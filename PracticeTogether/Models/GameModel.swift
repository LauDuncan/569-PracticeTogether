/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents the current state of the game
  in the SharePlay group session.
*/

import Foundation
import GroupActivities

struct GameModel: Codable, Hashable, Sendable {
    /// The game's current state, which includes pre-game and in-game stages.
    var stage: ActivityStage = .scenarioSelection
    
    /// A set of categories that don't apply to the current game.
    var excludedCategories = Set<String>()
    
    /// A record of all the player's turns throughout the game, which the app updates when the player completes a turn.
    var turnHistory: [Participant.ID] = []
    
    /// The ending time of the current round, which the app sets at the beginning of each turn.
    var currentRoundEndTime: Date?
}

extension GameModel {
    /// The app's states during gameplay.
    enum GameStage: Codable, Hashable, Sendable {
        case beforePlayersTurn
        case duringPlayersTurn
        case afterPlayersTurn
    }
    
    enum ActivityStage: Codable, Hashable, Sendable {
        case scenarioSelection
        case roleSelection
        case inGame(GameStage)
        case debrief
        
        var isInGame: Bool {
            if case .inGame = self {
                true
            } else {
                false
            }
        }
    }
}
