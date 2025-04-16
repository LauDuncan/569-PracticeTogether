import SwiftUI

// A view that displays debrief status information in the window
struct DebriefRoomView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @State var showEndActivityConfirmation: Bool = false
    
    let rolesToDisplay: [PlayerModel.Role] = [.blue, .red, .yellow]

    var body: some View {
        HStack {
            Text("Debriefing in Progress")
            
        }
        .padding()
        .practiceTogetherToolbar()
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !appModel.isImmersiveSpaceOpen {
                    Button("Open Immersive Space", systemImage: "mountain.2.fill") {
                        Task {
                            await openImmersiveSpace(id: DebriefSpace.spaceID)
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
}
