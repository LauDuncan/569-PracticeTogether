/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the scenario selection view.
*/

import SwiftUI

/// A view that allows activity participants to select which scenario
/// they'd like to practice with.
///
///```
/// ┌────────────────────────────────────┐
/// │                                    │
/// │ Code Blue Simulation            □  │
/// │ Simulation 2                    ■  │
/// │ Simulation 3                    □  │
/// │ ...                             □  │
/// │                                    │
/// │                                    │
/// │             ┌────────┐             │
/// │             │ Play ▶ │             │
/// │             └────────┘             │
/// └────────────────────────────────────┘
/// ```
struct ScenarioSelectionView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        // Present the gameplay category options.
        Form {
            
            Section {
                Text("Code Blue")
//                ForEach(PhraseManager.shared.categories, id: \.self) { category in
//                    Toggle(category.description, isOn: isCategoryActive(category))
//                }
            } header: {
                Text("Scenarios")
            } footer: {
                Text("Select the scenario you'd like to practice with.")
            }
        }
        .practiceTogetherToolbar()
        
        Button("Play", systemImage: "play") {
            appModel.sessionController?.enterRoleSelection()
        }
        .padding(.vertical)
    }
}
