/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A class that creates a volume so that a person can create meshes with the location of the drag gesture, adapted for SharePlay.
*/

import SwiftUI
import RealityKit
import GroupActivities
import Combine
import simd

/// Manages the 3D canvas environment and visual representation of strokes based on ShareableStroke data.
@MainActor
class PaintingCanvas {
    /// The main root entity for the painting canvas.
    let root = Entity()
    
    /// Reference to the session controller.
    private var sessionController: SessionController
    
    /// Dictionary mapping ShareableStroke IDs to their visual representation entities.
    private var strokeVisuals: [UUID: StrokeVisual] = [:]
    
    /// Stores cancellables for observing changes.
    private var cancellables = Set<AnyCancellable>()

    /// The identifier for the currently active local stroke, if any.
    var currentLocalStrokeID: UUID?

    /// The distance for the box that extends in the positive direction.
    let big: Float = 1E2
    
    /// The distance for the box that extends in the negative direction.
    let small: Float = 1E-2

    // Sets up the painting canvas, collision boxes, and observes strokes.
    init(sessionController: SessionController) {
        self.sessionController = sessionController
        
        setupCollisionBoxes()
        observeGameModel() // Start observing strokes from the game model
    }

    private func setupCollisionBoxes() {
        root.addChild(addBox(size: [big, big, small], position: [0, 0, -0.5 * big]))
        root.addChild(addBox(size: [big, big, small], position: [0, 0, +0.5 * big]))
        root.addChild(addBox(size: [big, small, big], position: [0, -0.5 * big, 0]))
        root.addChild(addBox(size: [big, small, big], position: [0, +0.5 * big, 0]))
        root.addChild(addBox(size: [small, big, big], position: [-0.5 * big, 0, 0]))
        root.addChild(addBox(size: [small, big, big], position: [+0.5 * big, 0, 0]))
    }

    /// Create a collision box that takes in user input with the drag gesture.
    private func addBox(size: SIMD3<Float>, position: SIMD3<Float>) -> Entity {
        let box = Entity()
        box.components.set(InputTargetComponent())
        box.components.set(CollisionComponent(shapes: [.generateBox(size: size)], isStatic: true))
        box.position = position
        return box
    }

    /// Observe changes in the game model's strokes dictionary.
    private func observeGameModel() {
        // Use a publisher to observe changes to the game's strokes
        let gamePublisher = sessionController.publisher(for: \.game)
        
        gamePublisher
            .map(\.strokes)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedStrokes in
                self?.syncStrokeVisuals(with: updatedStrokes)
            }
            .store(in: &cancellables)
    }

    /// Synchronizes the `strokeVisuals` dictionary and the RealityKit scene with the game's state.
    private func syncStrokeVisuals(with shareableStrokes: [UUID: ShareableStroke]) {
        // Remove visuals for strokes that no longer exist
        let strokesToRemove = strokeVisuals.keys.filter { shareableStrokes[$0] == nil }
        for id in strokesToRemove {
            if let visual = strokeVisuals.removeValue(forKey: id) {
                root.removeChild(visual.entity)
                print("Removed visual for stroke \(id)")
            }
        }

        // Add or update visuals for existing strokes
        for (id, shareableStroke) in shareableStrokes {
            if let existingVisual = strokeVisuals[id] {
                // Update existing visual if points changed
                if existingVisual.points.count != shareableStroke.points.count || existingVisual.isFinished != shareableStroke.isFinished {
                    existingVisual.points = shareableStroke.points
                    existingVisual.isFinished = shareableStroke.isFinished
                    existingVisual.updateMesh()
                    print("Updated visual for stroke \(id)")
                }
            } else {
                // Create new visual
                let newVisual = StrokeVisual(points: shareableStroke.points, isFinished: shareableStroke.isFinished)
                strokeVisuals[id] = newVisual
                root.addChild(newVisual.entity)
                print("Added visual for stroke \(id)")
            }
        }
    }

    // --- Local Drawing Actions (Triggered by View Gestures) ---

    /// Starts a new local stroke and notifies the session controller.
    func startLocalStroke() {
        // Call the session controller to start the stroke
        let newStroke = sessionController.startStroke()
        self.currentLocalStrokeID = newStroke.id
        
        // Visual representation will be created/updated by the game model observer
    }

    /// Adds a point to the current local stroke and notifies the session controller.
    func addPointToLocalStroke(_ position: SIMD3<Float>) {
        guard let strokeID = currentLocalStrokeID else {
            // print("Cannot add point: No active local stroke.") // Can be noisy
            return
        }

        /// The maximum distance between two points before requiring a new point.
        let threshold: Float = 1E-9
        
        // Get the latest points for the current stroke from the game state
        guard let currentPoints = sessionController.game.strokes[strokeID]?.points else {
            print("Warning: Could not find current points for stroke \(strokeID) in game state.")
            return
        }

        // Check distance threshold against the last point *in the shared state*
        if let previousPoint = currentPoints.last, length(position - previousPoint) < threshold {
            return
        }

        // Notify the session controller to add the point (which updates shared state and triggers sync)
        sessionController.addPoint(position, to: strokeID)
    }

    /// Finishes the current local stroke and notifies the session controller.
    func finishLocalStroke() {
        guard let strokeID = currentLocalStrokeID else {
            // print("Cannot finish stroke: No active local stroke.") // Can be noisy
            return
        }
        sessionController.finishStroke(strokeID: strokeID)
        self.currentLocalStrokeID = nil
        
        // Final visual update will happen via the game model observer
    }
}
