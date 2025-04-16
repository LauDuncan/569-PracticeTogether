/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main UI view, which presents different subviews based on the app's current state.
*/

import GroupActivities
import SwiftUI

/// A top-level content view that presents the app's user interface based on
/// the app's current stage.
///
/// Practice Together has four stages:
///
/// 1. A welcome stage that is presented when you first launch the app and
///    invites you to create a SharePlay group session with your current
///    FaceTime call.
///
/// 2. A scenario selection stage where you’ll decide what scenario you want
///    to practice with.
///
/// 3. A team selection stage where you’ll decide which role you would like to act as.
///
/// 4. A game stage where Practice Together will open an immersive space and
///    present a view with view of which player is assigned what role and a timer.
///    An additional view appears in front of the player with the 'charge nurse' role, for
///    them to control the state of the scenario of the group.

struct MainView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        Group {
            // Select the appropriate view for each stage in the game.
            switch appModel.sessionController?.game.stage {
                case .none:
                    WelcomeView()
                case .scenarioSelection:
                    ScenarioSelectionView()
                case .roleSelection:
                    RoleSelectionView()
                case .inGame:
                    ScenarioStatusView()
                case .debrief:
                    DebriefView()
            }
        }
        .task(observeGroupSessions)
    }
    
    /// Monitor for new Guess Together group activity sessions.
    @Sendable
    func observeGroupSessions() async {
        for await session in PracticeTogetherActivity.sessions() {
            let sessionController = await SessionController(session, appModel: appModel)
            guard let sessionController else {
                continue
            }
            appModel.sessionController = sessionController

            // Create a task to observe the group session state and clear the
            // session controller when the group session invalidates.
            Task {
                for await state in session.$state.values {
                    guard appModel.sessionController?.session.id == session.id else {
                        return
                    }

                    if case .invalidated = state {
                        appModel.sessionController = nil
                        return
                    }
                }
            }
        }
    }
}
