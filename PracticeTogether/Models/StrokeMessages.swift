/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Message types for stroke synchronization in SharePlay.
*/

import Foundation
import GroupActivities
import simd

/// Messages for synchronizing stroke operations across participants
enum StrokeMessage: Codable, Sendable {
    case startStroke(stroke: ShareableStroke) // Send when a new stroke begins
    case addPoint(strokeID: UUID, point: SIMD3<Float>) // Send frequently during drawing
    case finishStroke(strokeID: UUID) // Send when drawing ends
    case deleteStroke(strokeID: UUID) // Optional: For deleting strokes
}

/// Messages for requesting full state updates for strokes
enum StateRequestMessage: Codable, Sendable {
    case sendCurrentState(strokes: [UUID: ShareableStroke])
}

/// Message for updating multiple strokes at once (used for full state updates)
struct StrokesUpdateMessage: Codable, Sendable {
    let strokes: [UUID: ShareableStroke]
    let timestamp: Date
} 