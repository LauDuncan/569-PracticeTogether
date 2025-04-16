/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The controller manages the app's active SharePlay session.
*/

import GroupActivities
import Observation

@Observable @MainActor
final class SessionController {
    let session: GroupSession<PracticeTogetherActivity>
    let messenger: GroupSessionMessenger
    let systemCoordinator: SystemCoordinator
    
    var game: GameModel {
        get {
            gameSyncStore.game
        }
        set {
            if newValue != gameSyncStore.game {
                gameSyncStore.game = newValue
                shareLocalGameState(newValue)
            }
        }
    }
    
    var gameSyncStore = GameSyncStore() {
        didSet {
            gameStateChanged()
        }
    }

    var players = [Participant: PlayerModel]() {
        didSet {
            if oldValue != players {
                updatePlayerRole()
                // updateLocalParticipantRole()
            }
        }
    }
    
    var localPlayer: PlayerModel {
        get {
            players[session.localParticipant]!
        }
        set {
            if newValue != players[session.localParticipant] {
                players[session.localParticipant] = newValue
                shareLocalPlayerState(newValue)
            }
        }
    }
    
    init?(_ groupSession: GroupSession<PracticeTogetherActivity>, appModel: AppModel) async {
        guard let groupSystemCoordinator = await groupSession.systemCoordinator else {
            return nil
        }

        session = groupSession

        // Create the group session messenger for the session controller, which it uses to keep the game in sync for all participants.
        messenger = GroupSessionMessenger(session: session)

        systemCoordinator = groupSystemCoordinator

        // Create a representation of the local participant.
        localPlayer = PlayerModel(
            id: session.localParticipant.id,
            name: appModel.playerName
        )
        appModel.showPlayerNameAlert = localPlayer.name.isEmpty
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()
        
        session.join()
    }
    
    func updateSpatialTemplatePreference() {
        switch game.stage {
            case .scenarioSelection:
                systemCoordinator.configuration.spatialTemplatePreference = .sideBySide
            case .roleSelection:
                systemCoordinator.configuration.spatialTemplatePreference = .custom(RoleSelectionTemplate())
            case .inGame:
                systemCoordinator.configuration.spatialTemplatePreference = .custom(GameTemplate())
            case .debrief:
                systemCoordinator.configuration.spatialTemplatePreference = .surround
        }
    }
    
    func updateLocalParticipantRole() {
        // Set and unset the participant's spatial template role based on updating game state.
        switch game.stage {
            case .scenarioSelection:
                systemCoordinator.resignRole()
            case .roleSelection:
                switch localPlayer.role {
                case .none:
                    systemCoordinator.resignRole()
                case .blue:
                    systemCoordinator.assignRole(RoleSelectionTemplate.Role.blueTeam)
                case .red:
                    systemCoordinator.assignRole(RoleSelectionTemplate.Role.redTeam)
                case .yellow:
                    systemCoordinator.assignRole(RoleSelectionTemplate.Role.yellowTeam)
                }
            case .inGame:
                switch localPlayer.role {
                case .none:
                    systemCoordinator.resignRole()
                case .red:
                    systemCoordinator.assignRole(GameTemplate.Role.defibNurse)
                case .blue:
                    systemCoordinator.assignRole(GameTemplate.Role.airwayNurse)
                case .yellow:
                    systemCoordinator.assignRole(GameTemplate.Role.chargeNurse)
                }
            case .debrief:
                systemCoordinator.resignRole()

                // if localPlayer.isPlaying {
                //     systemCoordinator.assignRole(GameTemplate.Role.chargeNurse)
                // } else if let currentPlayer {
                //     if currentPlayer.role == (PlayerModel.Role) .red {
                //         systemCoordinator.assignRole(GameTemplate.Role.defibNurse)
                //     }
                //     else if currentPlayer.role == (PlayerModel.Role) .blue {
                //         systemCoordinator.assignRole(GameTemplate.Role.airwayNurse)
                //     }
                //     else {
                //         systemCoordinator.resignRole()
                //     }
                // }
        }
    }

    func updatePlayerRole() {
        // This function ensures role exclusivity and updates spatial positioning
        guard let role = localPlayer.role else {
            // If the player has no role, ensure they have no spatial role assigned
            systemCoordinator.resignRole()
            return
        }

        // Check if another player already has this role
        let roleIsTaken = players.values.contains { player in
            player.id != localPlayer.id && player.role == role
        }

        if roleIsTaken {
            // If role is taken, remove it from the local player and their spatial assignment
            localPlayer.role = nil
            systemCoordinator.resignRole()
            print("Player picked a role (\(role.name)) that is already taken, resigning role.")
            // Share this change so others know the role is free again
            shareLocalPlayerState(localPlayer)
        } else {
            // If role is not taken, assign the correct spatial position
            updateLocalParticipantRole()
        }
    }
    
    func configureSystemCoordinator() {
        // Let the system coordinator show each players' spatial Persona in the immersive space.
        systemCoordinator.configuration.supportsGroupImmersiveSpace = true
        
        Task {
            // Wait for gameplay updates from participants.
            for await localParticipantState in systemCoordinator.localParticipantStates {
                localPlayer.seatPose = localParticipantState.seat?.pose
            }
        }
    }

    func enterRoleSelection() {
        game.stage = .roleSelection
        game.currentRoundEndTime = nil
        game.turnHistory.removeAll()
    }
    
    func joinRole(_ role: PlayerModel.Role?) {
        localPlayer.role = role
    }
    
    func startGame() {
        game.stage = .inGame(.beforePlayersTurn)
    }
    
//    func beginTurn() {
//        // Set the new turn game state.
//        game.stage = .inGame(.duringPlayersTurn)
//        game.currentRoundEndTime = .now.addingTimeInterval(30)
//        
//        // Wait thirty seconds before ending the current turn.
//        let sleepUntilTime = ContinuousClock.now.advanced(by: .seconds(30))
//        Task {
//            try await Task.sleep(until: sleepUntilTime)
//            if case .inGame(.duringPlayersTurn) = game.stage {
//                game.stage = .inGame(.afterPlayersTurn)
//            }
//        }
//    }
    
    func endGame() {
        game.stage = .scenarioSelection
        localPlayer.role = nil
        shareLocalPlayerState(localPlayer)
        updatePlayerRole()
    }
    
    func gameStateChanged() {
        if game.stage == .scenarioSelection {
            localPlayer.isPlaying = false
            localPlayer.score = 0
        }
        
        // Update spatial template and player roles whenever game state changes
        updateSpatialTemplatePreference()
        updatePlayerRole()
        updateLocalParticipantRole()
    }

    func assignRole(_ role: PlayerModel.Role?) {
        // Assign the role locally first
        localPlayer.role = role
        // Share the state *before* checking for conflicts/updating spatial position
        shareLocalPlayerState(localPlayer)
        // Check for conflicts and update spatial position
        updatePlayerRole()
    }
}
