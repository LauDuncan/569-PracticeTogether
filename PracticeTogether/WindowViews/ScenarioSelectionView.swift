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
    let items = ["Code Blue", "Sepsis Alert Protocol", "Respiratory Distress", "Seizure Management", "Opioid Overdose", "Suicidal Intervention"]
    @State private var selectedItem: String? = nil
    
    var body: some View {
        // Present the gameplay category options.
        VStack {
            Text("Select a Scenario")
                .font(.headline)

            ForEach(items, id: \.self) { item in
                Button(action: {
                    selectedItem = item
                }) {
                    Text(item)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedItem == item ? Color.blue : Color.clear)
                        .foregroundColor(selectedItem == item ? .white : .white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle()) // Removes default button styling
            }
        }
        .padding()
        .practiceTogetherToolbar()
        
        Button("Play", systemImage: "play") {
            appModel.sessionController?.enterRoleSelection()
            // appModel.sessionController?.enterDebriefRoom()
        }
        .padding(.vertical)
    }
}
