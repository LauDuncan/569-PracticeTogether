/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that displays each team's score next to the round's timer during a game.
*/

import SwiftUI

/// ```
/// ┌────────────────────────────────────┐
/// │ Blue Team                          │
/// │ ────────────                       │
/// │ 3                                  │
/// │                                    │
/// │                        00:27       │
/// │ Red Team                           │
/// │ ────────────                       │
/// │ 4                                  │
/// │                                    │
/// └────────────────────────────────────┘
/// ```

struct ScenarioStatusView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State var showEndActivityConfirmation: Bool = false
    
    let rolesToDisplay: [PlayerModel.Role] = [.blue, .red, .yellow]

    var body: some View {
        HStack {
            List {
                ForEach(rolesToDisplay, id: \.self) { role in
                    if roleIsOccupied(role) {
                        RoleStatusView(role: role)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            
            // Group {
            //     // Report the time remaining before, during, and after a round.
            //     if let currentRoundEndTime = appModel.sessionController?.game.currentRoundEndTime {
            //         if currentRoundEndTime > .now {
            //             Text(timerInterval: .now...currentRoundEndTime)
            //         } else {
            //             Text("0:00")
            //         }
            //     } else {
            //         Text("0:30")
            //     }
            // }
            // .font(.system(size: 150, weight: .bold))
            // .frame(maxWidth: .infinity)
        }
        .padding()
        .practiceTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !appModel.isImmersiveSpaceOpen {
                    Button("Open Immersive Space", systemImage: "mountain.2.fill") {
                        Task {
                            await openImmersiveSpace(id: GameSpace.spaceID)
                        }
                    }
                }
                
                Button("End activity", systemImage: "xmark") {
                    showEndActivityConfirmation = true
                }
            }
        }
        .confirmationDialog("End the activity for everyone?", isPresented: $showEndActivityConfirmation, titleVisibility: .visible) {
            Button("End activity", role: .destructive) {
                appModel.sessionController?.endGame()
            }
        }
    }
    
    func roleIsOccupied(_ role: PlayerModel.Role) -> Bool {
        guard let sessionController = appModel.sessionController else { return false }
        return sessionController.players.values.contains { $0.role == role }
    }
}

/// A view that lists a team's players and their scores.
struct RoleStatusView: View {
    @Environment(AppModel.self) var appModel
    
    let role: PlayerModel.Role
    
    var players: [PlayerModel] {
        guard let sessionController = appModel.sessionController else {
            return []
        }
        
        return sessionController.players.values.filter { player in
            player.role == role
        }
        .sorted(using: KeyPathComparator(\.id))
    }
    
    var body: some View {
        Section(role.name) {
            ForEach(players) { player in
                Text(player.name)
                    .fontWeight(player.id == appModel.sessionController?.localPlayer.id ? .bold : .regular)
            }
        }
    }
}
//
//  ScenarioStatusView.swift
//  PracticeTogether
//
//  Created by Duncan Lau on 4/2/25.
//

