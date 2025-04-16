/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An immersive space for debriefing after the game.
*/

import SwiftUI

struct DebriefSpace: Scene {
    @Environment(AppModel.self) var appModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    static let spaceID = "DebriefSpace"
    
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
                DebriefView()
            }
            .onAppear {
                appModel.isDebriefSpaceOpen = true
            }
            .onDisappear {
                appModel.isDebriefSpaceOpen = false
            }
        }
        .onChange(of: appModel.sessionController?.game.stage, updateImmersiveSpaceState)
        .immersionStyle(selection: immersionStyleBinding)
    }
    
    /// Opens or dismisses the debrief immersive space based on the game's current and previous states.
    ///
    /// - Parameters:
    ///     - oldActivityStage: The app's previous activity stage.
    ///     - newActivityStage: The app's current stage.
    func updateImmersiveSpaceState(
        oldActivityStage: GameModel.ActivityStage?,
        newActivityStage: GameModel.ActivityStage?
    ) {
        let wasInDebrief = oldActivityStage == .debrief
        let isInDebrief = newActivityStage == .debrief
        
        guard wasInDebrief != isInDebrief else {
            return
        }
        
        print("DebriefSpace detected stage change: \(oldActivityStage.debugDescription) → \(newActivityStage.debugDescription)")
        
        Task {
            // if isInDebrief && !appModel.isDebriefSpaceOpen {
            //     await openImmersiveSpace(id: Self.spaceID)
            // } else if appModel.isDebriefSpaceOpen {
            //     await dismissImmersiveSpace()
            // }

            await appModel.immersiveSpaceCoordinator.handleStageChange(
                from: oldActivityStage,
                to: newActivityStage,
                openSpace: { spaceID in try await openImmersiveSpace(id: spaceID) },
                dismissSpace: { try await dismissImmersiveSpace() }
            )
        }
    }
} 