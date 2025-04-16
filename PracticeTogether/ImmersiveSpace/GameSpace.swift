/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An immersive space the game presents during the in-game stages.
*/

import SwiftUI

struct GameSpace: Scene {
    @Environment(AppModel.self) var appModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    static let spaceID = "GameSpace"
    
    // Create a Binding to the AppModel's progressiveImmersion property
    private var immersionStyleBinding: Binding<ImmersionStyle> {
        Binding(
            get: { self.appModel.progressiveImmersion },
            set: { self.appModel.progressiveImmersion = $0 }
        )
    }
    
    var body: some Scene {
        ImmersiveSpace(id: Self.spaceID) {
            ZStack {
                ScenarioManagementView()
//                PhraseDeckPodiumView()
//                SeatScoresView()
            }
            .onAppear {
                appModel.isImmersiveSpaceOpen = true
            }
            .onDisappear {
                appModel.isImmersiveSpaceOpen = false
            }
        }
        .onChange(of: appModel.sessionController?.game.stage, updateImmersiveSpaceState)
        .immersionStyle(selection: .constant(.full), in: .full)
        // .immersionStyle(selection: immersionStyleBinding, in: .progressive)
    }
    
    /// Opens or dismisses the app's immersive space based on the game's current and previous states.
    ///
    /// - Parameters:
    ///     - oldActivityStage: The app's previous activity stage.
    ///     - newActivityStage: The app's current stage.
    func updateImmersiveSpaceState(
        oldActivityStage: GameModel.ActivityStage?,
        newActivityStage: GameModel.ActivityStage?
    ) {
        let wasInGame = oldActivityStage?.isInGame ?? false
        let isInGame = newActivityStage?.isInGame ?? false
        
        guard wasInGame != isInGame else {
            return
        }
        
        print("GameSpace detected stage change: \(oldActivityStage.debugDescription) → \(newActivityStage.debugDescription)")
        
        Task {
            // if isInGame && !appModel.isImmersiveSpaceOpen {
            //     await openImmersiveSpace(id: Self.spaceID)
            // } else if appModel.isImmersiveSpaceOpen {
            //     await dismissImmersiveSpace()
            // }

            // Use the coordinator to handle the transition
            await appModel.immersiveSpaceCoordinator.handleStageChange(
                from: oldActivityStage,
                to: newActivityStage,
                openSpace: { spaceID in try await openImmersiveSpace(id: spaceID) },
                dismissSpace: { try await dismissImmersiveSpace() }
            )
        }
    }
}
