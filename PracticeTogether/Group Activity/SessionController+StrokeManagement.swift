/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Extension of SessionController that handles stroke management and synchronization.
*/

import Foundation
import GroupActivities
import simd

// MARK: - Stroke Management
extension SessionController {
    
    // MARK: - Local Stroke Methods
    
    /// Starts a new stroke and returns it
    @MainActor
    func startStroke() -> ShareableStroke {
        let participantID = session.localParticipant.id
        let newStroke = ShareableStroke(participantID: participantID)
        
        // Update local state
        var updatedGame = game
        updatedGame.strokes[newStroke.id] = newStroke
        game = updatedGame
        
        // Send message to other participants
        sendStrokeMessage(.startStroke(stroke: newStroke))
        
        return newStroke
    }
    
    /// Adds a point to an existing stroke
    @MainActor
    func addPoint(_ point: SIMD3<Float>, to strokeID: UUID) {
        var updatedGame = game
        guard updatedGame.strokes[strokeID] != nil else {
            print("Warning: Tried to add point to non-existent stroke \(strokeID)")
            return
        }
        
        // Update local state
        updatedGame.strokes[strokeID]?.points.append(point)
        game = updatedGame
        
        // Send message to other participants
        sendStrokeMessage(.addPoint(strokeID: strokeID, point: point))
    }
    
    /// Marks a stroke as finished
    @MainActor
    func finishStroke(strokeID: UUID) {
        var updatedGame = game
        guard updatedGame.strokes[strokeID] != nil else {
            print("Warning: Tried to finish non-existent stroke \(strokeID)")
            return
        }
        
        // Update local state
        updatedGame.strokes[strokeID]?.isFinished = true
        game = updatedGame
        
        // Send message to other participants
        sendStrokeMessage(.finishStroke(strokeID: strokeID))
    }
    
    /// Deletes a stroke
    @MainActor
    func deleteStroke(strokeID: UUID) {
        var updatedGame = game
        guard updatedGame.strokes[strokeID] != nil else {
            print("Warning: Tried to delete non-existent stroke \(strokeID)")
            return
        }
        
        // Update local state
        updatedGame.strokes.removeValue(forKey: strokeID)
        game = updatedGame
        
        // Send message to other participants
        sendStrokeMessage(.deleteStroke(strokeID: strokeID))
    }
    
    // MARK: - Message Handling
    
    /// Sends a stroke message to all participants
    private func sendStrokeMessage(_ message: StrokeMessage) {
        Task {
            do {
                try await messenger.send(message)
            } catch {
                print("Error sending stroke message: \(error)")
            }
        }
    }
    
    /// Sends all current strokes to specified participants
    func sendFullStrokeState(to participants: Set<Participant>) {
        guard !game.strokes.isEmpty else { return }
        
        let message = StateRequestMessage.sendCurrentState(strokes: game.strokes)
        
        Task {
            do {
                try await messenger.send(message, to: .only(participants))
                print("Sent full stroke state (\(game.strokes.count) strokes) to selected participants")
            } catch {
                print("Error sending full stroke state: \(error)")
            }
        }
    }
    
    /// Sends a batch update of multiple strokes
    func sendStrokesUpdate(_ strokes: [UUID: ShareableStroke]) {
        let message = StrokesUpdateMessage(strokes: strokes, timestamp: Date())
        
        Task {
            do {
                try await messenger.send(message)
                print("Sent stroke update with \(strokes.count) strokes")
            } catch {
                print("Error sending strokes update: \(error)")
            }
        }
    }
    
    /// Starts drawing mode
    func enterDrawingMode() {
        var updatedGame = game
        updatedGame.stage = .drawing
        game = updatedGame
    }
    
    /// Exits drawing mode and returns to previous state
    func exitDrawingMode() {
        var updatedGame = game
        updatedGame.stage = .inGame(.beforePlayersTurn)
        game = updatedGame
    }
} 