/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The implementation for an observable model that maintains the app's state.
*/

import Foundation
import SwiftUI
import Observation

@Observable @MainActor
final class AppModel {
    var sessionController: SessionController?
    
    // Coordinator for managing immersive space transitions
    var immersiveSpaceCoordinator: ImmersiveSpaceCoordinator!
    
    var playerName: String = UserDefaults.standard.string(forKey: "player-name") ?? "" {
        didSet {
            UserDefaults.standard.set(playerName, forKey: "player-name")
            sessionController?.localPlayer.name = playerName
        }
    }
    
    var progressiveImmersion: ImmersionStyle = .progressive(0.1...1.0, initialAmount: 0.6)

    var showPlayerNameAlert = false
    
    // Immersive space tracking
    var isImmersiveSpaceOpen = false
    var isDebriefSpaceOpen = false
    
    // Session statistics for debrief
    var sessionStartTime: Date?
    var sessionDuration: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    var completedScenarios: Int = 0
    
    init() {
        // Initialize self first, then set up the coordinator
        self.immersiveSpaceCoordinator = ImmersiveSpaceCoordinator(appModel: self)
    }
}
