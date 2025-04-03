/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that invites activity participants to assign themselves a role in the scenario.
*/

import SwiftUI

/// ```
/// ┌──────────────────────────────────┐
/// │ Role 1           Role 2          │
/// │ ───────────────  ─────────────── │
/// │ ...                              │
/// │                  Act as role 2   │
/// │                                  │
/// │ Leave Role                       │
/// │                                  │
/// │                                  │
/// │            ┌───────┐             │
/// │            │Ready ▶│             │
/// │            └───────┘             │
/// └──────────────────────────────────┘
/// ```
struct RoleSelectionView: View {
    @Environment(AppModel.self) var appModel
    
    let availableRoles: [PlayerModel.Role] = [.red, .yellow, .blue]

    var body: some View {
        VStack {
            HStack {
                // Display a list/section for each available role
                ForEach(availableRoles, id: \.self) { role in
                    RoleList(role: role)
                }
            }
            
            Button("Ready", systemImage: "checkmark") {
                appModel.sessionController?.startGame()
            }
            .tint(.green)
            .disabled(noRolesSelected)
        }
        .padding()
        .practiceTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    appModel.sessionController?.endGame()
                }
            }
        }
    }
    
    // Check if the "Ready" button is disabled
    var noRolesSelected: Bool {
        guard let sessionController = appModel.sessionController else { return true }
        // Check if at least one player has selected any role
        return !sessionController.players.values.contains { $0.role != nil }
    }
}


struct RoleList: View {
    @Environment(AppModel.self) var appModel
    
    // The specific role this list section represents
    let role: PlayerModel.Role
    
    var body: some View {
        List {
            // Display role name as the section header
            Section(role.name) {
                ForEach(playersInRole(role)) { player in
                    Text(player.name)
                        .fontWeight(player.id == appModel.sessionController?.localPlayer.id ? .bold : .regular)
                }
                
                // Show "Join" button if local player doesn't have this role
                if appModel.sessionController?.localPlayer.role != role {
                    Button("Act as \(role.name)", systemImage: "person.fill.badge.plus") {
                        // Call assignRole to select this role
                        appModel.sessionController?.assignRole(role)
                    }
                    .foregroundStyle(role.color.gradient)
                } else {
                    // Show "Leave" button if local player currently has this role
                    Button("Leave Role", systemImage: "person.fill.badge.minus") {
                        // Call assignRole with nil to leave the role
                        appModel.sessionController?.assignRole(nil)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // Updated function to filter players by the specific role for this list
    func playersInRole(_ targetRole: PlayerModel.Role) -> [PlayerModel] {
        guard let sessionController = appModel.sessionController else {
            return []
        }
        
        // Filter players whose role matches the targetRole for this section
        return sessionController.players.values.lazy.filter { player in
            player.role == targetRole && !player.name.isEmpty
        }
        .sorted(using: KeyPathComparator(\.id))
    }
}

//#Preview {
//    TeamSelectionView()
//        .environment(AppModel())
//}

