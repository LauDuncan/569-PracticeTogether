import Foundation
import GroupActivities // Need Participant ID
import simd // Need SIMD3

// Represents stroke data that can be encoded and shared.
struct ShareableStroke: Codable, Identifiable {
    let id: UUID // Unique identifier for the stroke
    var points: [SIMD3<Float>] // Points making up the stroke path
    // Make participantID optional to support local-only strokes
    let participantID: Participant.ID? 
    var timestamp: Date // Timestamp for potential conflict resolution
    var isFinished: Bool = false // Flag to indicate if the stroke is complete

    // Update initializer to accept optional participantID
    init(id: UUID = UUID(), points: [SIMD3<Float>] = [], participantID: Participant.ID?, timestamp: Date = Date()) {
        self.id = id
        self.points = points
        self.participantID = participantID
        self.timestamp = timestamp
    }
} 