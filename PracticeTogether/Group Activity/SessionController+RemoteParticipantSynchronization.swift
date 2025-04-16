/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A session controller extension that synchronizes the app's state with the SharePlay group session.
*/

import GroupActivities

extension SessionController {
    func shareLocalPlayerState(_ newValue: PlayerModel) {
        Task {
            do {
                // Send local player state with the group session messenger.
                try await messenger.send(newValue)
            } catch {
                print("The app can't send the player state message due to: \(error)")
            }
        }
    }
    
    func shareLocalGameState(_ newValue: GameModel) {
        gameSyncStore.editCount += 1
        gameSyncStore.lastModifiedBy = session.localParticipant
    
        let message = GameMessage(
            game: newValue,
            editCount: gameSyncStore.editCount
        )
        Task {
            do {
                // Send local game state with the group session messenger.
                try await messenger.send(message)
            } catch {
                print("The app can't send the game state message due to: \(error)")
            }
        }
    }
    
    func observeRemoteParticipantUpdates() {
        observeActiveRemoteParticipants()
        observeRemoteGameModelUpdates()
        observeRemotePlayerModelUpdates()
        observeRemoteStrokeMessages()
        observeRemoteStateRequestMessages()
        observeRemoteStrokesUpdateMessages()
    }
    
    private func observeRemoteGameModelUpdates() {
        Task {
            // Listen for game state messages from other players with the group session messenger.
            // Update local game state with the returned message and context.
            for await (message, context) in messenger.messages(of: GameMessage.self) {
                let senderID = context.source.id
                
                let editCount = gameSyncStore.editCount
                let gameLastModifiedBy = gameSyncStore.lastModifiedBy ?? session.localParticipant
                let shouldAcceptMessage = if message.editCount > editCount {
                    true
                } else if message.editCount == editCount && senderID > gameLastModifiedBy.id {
                    true
                } else {
                    false
                }
                
                guard shouldAcceptMessage else {
                    continue
                }
                
                if message.game != gameSyncStore.game {
                    gameSyncStore.game = message.game
                }
                gameSyncStore.editCount = message.editCount
                gameSyncStore.lastModifiedBy = context.source
            }
        }
    }
    
    private func observeRemotePlayerModelUpdates() {
        Task {
            for await (player, context) in messenger.messages(of: PlayerModel.self) {
                players[context.source] = player
            }
        }
    }
    
    // MARK: - Stroke Message Observation
    
    /// Observes stroke messages and updates the game state
    private func observeRemoteStrokeMessages() {
        Task {
            for await (message, context) in messenger.messages(of: StrokeMessage.self) {
                await MainActor.run {
                    handleStrokeMessage(message, from: context.source)
                }
            }
        }
    }
    
    /// Handles incoming stroke messages
    @MainActor
    private func handleStrokeMessage(_ message: StrokeMessage, from participant: Participant) {
        var updatedGame = game
        
        switch message {
        case .startStroke(let stroke):
            // Only accept if it has a valid participantID and we don't have it already (or it's newer)
            if stroke.participantID != nil && (updatedGame.strokes[stroke.id] == nil || 
                                           (updatedGame.strokes[stroke.id]?.timestamp ?? .distantPast) < stroke.timestamp) {
                updatedGame.strokes[stroke.id] = stroke
                print("Received startStroke for \(stroke.id) from \(stroke.participantID?.debugDescription ?? "unknown")")
            }
            
        case .addPoint(let strokeID, let point):
            if updatedGame.strokes[strokeID] != nil {
                updatedGame.strokes[strokeID]?.points.append(point)
            } else {
                // If we receive a point for a stroke we don't know, create an empty one
                let newStroke = ShareableStroke(id: strokeID, points: [point], participantID: participant.id)
                updatedGame.strokes[strokeID] = newStroke
                print("Received point for unknown stroke \(strokeID), created it.")
            }
            
        case .finishStroke(let strokeID):
            if updatedGame.strokes[strokeID] != nil {
                updatedGame.strokes[strokeID]?.isFinished = true
                print("Received finishStroke for \(strokeID)")
            } else {
                print("Received finishStroke for unknown stroke \(strokeID)")
            }
            
        case .deleteStroke(let strokeID):
            if updatedGame.strokes.removeValue(forKey: strokeID) != nil {
                print("Removed stroke \(strokeID) based on message.")
            }
        }
        
        // Update game state
        game = updatedGame
    }
    
    /// Observes state request messages
    private func observeRemoteStateRequestMessages() {
        Task {
            for await (message, context) in messenger.messages(of: StateRequestMessage.self) {
                await MainActor.run {
                    handleStateRequestMessage(message, from: context.source)
                }
            }
        }
    }
    
    /// Handles incoming state request messages
    @MainActor
    private func handleStateRequestMessage(_ message: StateRequestMessage, from participant: Participant) {
        switch message {
        case .sendCurrentState(let remoteStrokes):
            print("Received current state with \(remoteStrokes.count) strokes from \(participant.id).")
            
            var updatedGame = game
            
            // Keep local-only strokes 
            let localOnlyStrokes = updatedGame.strokes.filter { $1.participantID == session.localParticipant.id }
            
            // Filter incoming strokes to ensure they have a participant ID
            let validRemoteStrokes = remoteStrokes.filter { $1.participantID != nil }
            
            // Merge strokes, keeping the newest based on timestamp
            updatedGame.strokes = localOnlyStrokes.merging(validRemoteStrokes) { (local, remote) -> ShareableStroke in
                return local.timestamp >= remote.timestamp ? local : remote
            }
            
            game = updatedGame
            print("Merged state: Now have \(game.strokes.count) strokes")
        }
    }
    
    /// Observes strokes update messages
    private func observeRemoteStrokesUpdateMessages() {
        Task {
            for await (message, context) in messenger.messages(of: StrokesUpdateMessage.self) {
                await MainActor.run {
                    handleStrokesUpdateMessage(message, from: context.source)
                }
            }
        }
    }
    
    /// Handles incoming strokes update messages
    @MainActor
    private func handleStrokesUpdateMessage(_ message: StrokesUpdateMessage, from participant: Participant) {
        print("Received strokes update with \(message.strokes.count) strokes from \(participant.id)")
        
        var updatedGame = game
        
        // Merge the received strokes with local ones, prioritizing newer timestamps
        for (strokeID, remoteStroke) in message.strokes {
            if let localStroke = updatedGame.strokes[strokeID] {
                // Keep the newer stroke
                if remoteStroke.timestamp > localStroke.timestamp {
                    updatedGame.strokes[strokeID] = remoteStroke
                }
            } else {
                // If we don't have this stroke locally, add it
                updatedGame.strokes[strokeID] = remoteStroke
            }
        }
        
        game = updatedGame
    }
    
    private func observeActiveRemoteParticipants() {
        // Create a list of remote participants by removing the local participant from the group
        // session's list of active participants.
        let activeRemoteParticipants = session.$activeParticipants.map {
            $0.subtracting([self.session.localParticipant])
        }
        .withPrevious()
        .values
        
        Task {
            // Listen for game state messages from other players with the group session messenger.
            // Update local game state with the returned message and context.
            for await (oldActiveParticipants, currentActiveParticipants) in activeRemoteParticipants {
                let oldActiveParticipants = oldActiveParticipants ?? []
                
                let newParticipants = currentActiveParticipants.subtracting(oldActiveParticipants)
                let removedParticipants = oldActiveParticipants.subtracting(currentActiveParticipants)
                
                if !newParticipants.isEmpty {
                    // Send new participants the current state of the game.
                    do {
                        let gameMessage = GameMessage(
                            game: game,
                            editCount: gameSyncStore.editCount
                        )
                        try await messenger.send(gameMessage, to: .only(newParticipants))
                    } catch {
                        print("Failed to send game catchup message, \(error)")
                    }
                    
                    // Send new participants the player model of the local participant.
                    do {
                        try await messenger.send(localPlayer, to: .only(newParticipants))
                    } catch {
                        print("Failed to send player catchup message, \(error)")
                    }
                    
                    // Send new participants the current stroke state
                    if !game.strokes.isEmpty {
                        sendFullStrokeState(to: newParticipants)
                    }
                }

                // Remove any participants that have left from the active players dictionary.
                for participant in removedParticipants {
                    players[participant] = nil
                }
            }
        }
    }
    
    struct GameSyncStore {
        var editCount: Int = 0
        var lastModifiedBy: Participant?
        var game = GameModel()
    }
}

struct GameMessage: Codable, Sendable {
    let game: GameModel
    let editCount: Int
}
