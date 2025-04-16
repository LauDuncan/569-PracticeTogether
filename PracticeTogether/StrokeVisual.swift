/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that represents the visual mesh for a single stroke, generated from points.
*/

import SwiftUI
import RealityKit
import simd

/// Represents the visual entity and mesh generation for a single stroke.
class StrokeVisual {
    /// The RealityKit entity representing this stroke.
    let entity = Entity()

    /// The collection of points in 3D space that define the stroke's path.
    /// This is set externally by PaintingCanvas based on ShareableStroke data.
    var points: [SIMD3<Float>] = []
    
    /// Flag indicating if the stroke is finished (used for mesh generation adjustments potentially).
    var isFinished: Bool = false

    /// The maximum radius of the stroke.
    private let maxRadius: Float = 1E-2

    /// The number of points in each ring of the mesh.
    private let pointsPerRing = 8

    /// Initializer
    init(points: [SIMD3<Float>] = [], isFinished: Bool = false) {
        self.points = points
        self.isFinished = isFinished
        // Set a default material
        updateMaterial(color: .white) // Default color
        // Initial mesh update
        updateMesh()
    }

    /// Update the mesh with the current points.
    func updateMesh() {
        guard !points.isEmpty else {
            // If points are empty, remove any existing mesh
            if entity.components.has(ModelComponent.self) {
                entity.components.remove(ModelComponent.self)
            }
            return
        }
        guard let center = points.first else { return }

        let (positions, normals, triangles) = generateMeshData()

        // Check if mesh generation resulted in valid data
        guard !positions.isEmpty, !normals.isEmpty, !triangles.isEmpty else {
             print("Warning: Mesh generation yielded no data for stroke visual.")
            // If mesh data is invalid, remove any existing mesh
            if entity.components.has(ModelComponent.self) {
                entity.components.remove(ModelComponent.self)
            }
             return
        }

        var contents = MeshResource.Contents()
        contents.instances = [MeshResource.Instance(id: "main", model: "model")]

        var part = MeshResource.Part(id: "part", materialIndex: 0)
        part.positions = MeshBuffer(positions)
        part.triangleIndices = MeshBuffer(triangles)
        part.normals = MeshBuffer(normals)

        contents.models = [MeshResource.Model(id: "model", parts: [part])]

        do {
            if let mesh = entity.model?.mesh {
                // Try replacing existing mesh content
                try mesh.replace(with: contents)
            } else {
                // Generate a new mesh resource
                let newMesh = try MeshResource.generate(from: contents)
                
                // Retrieve existing material or use default
                let material = entity.model?.materials.first ?? SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)
                
                entity.components.set(ModelComponent(
                    mesh: newMesh,
                    materials: [material]
                ))
                
                // Set position only when creating the entity initially
                // Subsequent updates only change mesh content
                entity.setTransformMatrix(.identity, relativeTo: nil)
                entity.setPosition(center, relativeTo: nil)
            }
        } catch {
            print("Error generating or replacing mesh for stroke visual: \(error)")
        }
    }
    
    /// Updates the material color of the stroke.
    func updateMaterial(color: UIColor) {
        let material = SimpleMaterial(color: color, roughness: 1.0, isMetallic: false)
        if entity.components.has(ModelComponent.self) {
             entity.model?.materials = [material]
        } else {
            // If no model component exists yet (e.g., on init before first mesh), store it for later.
            // For simplicity, we'll just set it here, assuming updateMesh will create the ModelComponent.
            // A more robust way might involve storing the material separately until ModelComponent is created.
            // entity.components.set(ModelComponent(mesh: <placeholder_or_empty>, materials: [material])) // Placeholder needed
             print("Setting material color, but ModelComponent doesn't exist yet.")
        }
    }

    // MARK: - Mesh Generation Helpers (mostly unchanged from original Stroke)

    private func generateMeshData() -> ([SIMD3<Float>], [SIMD3<Float>], [UInt32]) {
        guard points.count > 1 else { return ([], [], []) } // Need at least 2 points for a line segment
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var triangles: [UInt32] = []
        
        // Use the first point as the reference origin for vertex positions
        let origin = points[0]

        for pointIdx in 0..<points.count {
            let (radius, direction) = calculateRadiusAndDirection(at: pointIdx)
            let (xAxis, yAxis) = calculateAxes(direction: direction)

            for ringPointIdx in 0..<pointsPerRing {
                 let (position, normal) = calculatePositionAndNormal(pointI: pointIdx, ringPointI: ringPointIdx, radius: radius, xAxis: xAxis, yAxis: yAxis, origin: origin)
                positions.append(position)
                normals.append(normal)

                if pointIdx + 1 < points.count {
                    appendTriangles(pointIdx: pointIdx, ringPointIdx: ringPointIdx, triangles: &triangles)
                }
            }
        }
        return (positions, normals, triangles)
    }

    private func calculateRadiusAndDirection(at index: Int) -> (Float, SIMD3<Float>) {
        // Taper ends: Use zero radius for the very first and very last points
        if index == 0 || (isFinished && index == points.count - 1) {
            let direction: SIMD3<Float>
            if points.count == 1 || index == 0 { // If only one point, or the first point
                 direction = SIMD3<Float>(0, 0, 1) // Default direction if no segment yet
            } else { // For the last point of a finished stroke
                 direction = normalize(points[index] - points[index - 1])
            }
             return (0, direction)
        } else if index + 1 < points.count { // Intermediate points
            let diff = points[index + 1] - points[index]
             let direction = normalize(diff)
             // Dynamic radius based on drawing speed (inverse of segment length)
             let speedFactor = clamp(maxRadius / (length(diff) + 1e-6), min: 0, max: 1.0) // Add epsilon to avoid division by zero
             let radius = maxRadius * powf(speedFactor, 0.3)
             return (radius, direction)
        } else { // Last point of an *unfinished* stroke
            // Use the direction and radius of the previous segment
             guard index > 0 else { return (0, SIMD3<Float>(0, 0, 1)) } // Should not happen if points.count > 1
             let diff = points[index] - points[index - 1]
             let direction = normalize(diff)
             let speedFactor = clamp(maxRadius / (length(diff) + 1e-6), min: 0, max: 1.0)
             let radius = maxRadius * powf(speedFactor, 0.3)
            return (radius, direction)
        }
    }
    
    // Ensure axes calculation handles vertical lines gracefully
    private func calculateAxes(direction: SIMD3<Float>) -> (SIMD3<Float>, SIMD3<Float>) {
        let upVector = SIMD3<Float>(0, 1, 0)
        var xAxis = normalize(cross(direction, upVector))
        // If direction is parallel to upVector, cross product is zero.
        // Choose a different vector (e.g., X-axis) to compute the cross product.
        if length_squared(xAxis) < 1e-6 {
             xAxis = normalize(cross(direction, SIMD3<Float>(1, 0, 0)))
        }
        let yAxis = normalize(cross(direction, xAxis))
        return (xAxis, yAxis)
    }

    private func calculatePositionAndNormal(pointI: Int, ringPointI: Int, radius: Float, xAxis: SIMD3<Float>, yAxis: SIMD3<Float>, origin: SIMD3<Float>) -> (SIMD3<Float>, SIMD3<Float>) {
        let angle = 2 * .pi * Float(ringPointI) / Float(pointsPerRing)
        let normal = cos(angle) * xAxis + sin(angle) * yAxis
        // Position relative to the stroke's origin point (first point)
        let position = (points[pointI] - origin) + radius * normal
        return (position, normal)
    }

    private func appendTriangles(pointIdx: Int, ringPointIdx: Int, triangles: inout [UInt32]) {
        // Indices for the four corners of the quad connecting two rings
        let currentRingStartIdx = UInt32(pointsPerRing * pointIdx)
        let nextRingStartIdx = UInt32(pointsPerRing * (pointIdx + 1))
        
        let idx0 = currentRingStartIdx + UInt32((ringPointIdx + 0) % pointsPerRing)
        let idx1 = nextRingStartIdx    + UInt32((ringPointIdx + 0) % pointsPerRing)
        let idx2 = currentRingStartIdx + UInt32((ringPointIdx + 1) % pointsPerRing)
        let idx3 = nextRingStartIdx    + UInt32((ringPointIdx + 1) % pointsPerRing)

        // First triangle (idx0, idx1, idx2) - winding order might need check
        triangles.append(contentsOf: [idx0, idx1, idx2])
        // Second triangle (idx2, idx1, idx3) - winding order might need check
        triangles.append(contentsOf: [idx2, idx1, idx3])
    }
}
