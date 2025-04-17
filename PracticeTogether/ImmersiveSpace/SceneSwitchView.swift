import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Button Model
struct MenuButtonModel: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let buttonType: MenuButtonType
    let horizontalPadding: CGFloat
    let sceneNumber: Int? // Associated scene number (1-4)
}

// MARK: - Button Types
enum MenuButtonType {
    case standard
    case debrief
    case exit
}

// MARK: - Content View
struct SceneSwitchView: View {
    @Environment(\.physicalMetrics) var converter
    @Environment(AppModel.self) var appModel
    
    // Callback function to activate scenes
    var activateScene: ((Int) -> Void)?
    
    // Single source of truth for which button is currently selected
    @State private var selectedButtonIndex: Int? = nil
    
    // Define all buttons in a single array
    private let menuButtons: [MenuButtonModel] = [
        MenuButtonModel(title: "Provide Oxygen", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 70, sceneNumber: 1),
        MenuButtonModel(title: "Place Defibrillator Pads", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 35, sceneNumber: 2),
        MenuButtonModel(title: "Set Defibrillation Energy", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 35, sceneNumber: 3),
        MenuButtonModel(title: "Provide Defib Shock", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 50, sceneNumber: 4),
        MenuButtonModel(title: "Debrief Room", iconName: "bubble.left.and.bubble.right.fill", buttonType: .debrief, horizontalPadding: 0, sceneNumber: nil)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Main action buttons
            ForEach(Array(menuButtons.enumerated()), id: \.element.id) { index, button in
                if button.buttonType != .exit {
                    ScenarioButton(
                        title: button.title,
                        iconName: button.iconName,
                        buttonType: button.buttonType,
                        horizontalPadding: button.horizontalPadding,
                        isSelected: selectedButtonIndex == index,
                        action: {
                            handleButtonTap(at: index)
                        }
                    )
                }
            }
            
            // Exit Button - kept separate since it has different styling
            Button(action: {
                handleExitTap()
            }) {
                HStack(spacing: 1) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Text("Exit")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .cornerRadius(50)
                .frame(width: 150)
                .frame(alignment: .center)
                .padding()
            }
        }
        .frame(width: 340, height: 600)
        .rotation3DEffect(Rotation3D(angle: .degrees(20), axis: .x), anchor: .center)
        .rotation3DEffect(Rotation3D(angle: .degrees(270), axis: .y), anchor: .center)
        .offset(y: -converter.convert(1.1, from: .meters))
    }
    
    // MARK: - Button Action Handlers
    private func handleButtonTap(at index: Int) {
        // Toggle selection state - if tapping the same button, it stays selected
        selectedButtonIndex = index
        
        // Perform the appropriate action based on the button type
        let button = menuButtons[index]
        switch button.buttonType {
        case .standard:
            print("Standard action button tapped: \(button.title)")
            
            // Activate the associated scene if available
            if let sceneNumber = button.sceneNumber {
                activateScene?(sceneNumber)
            }
            
            // Track completion
            appModel.completedScenarios += 1
            
        case .debrief:
            print("Debrief Room button tapped")
            // Start the session timer if not already started
            if appModel.sessionStartTime == nil {
                appModel.sessionStartTime = Date()
            }
            // Transition to debrief stage
            appModel.sessionController?.game.stage = .debrief
            
        case .exit:
            // Should not reach here as exit is handled separately
            break
        }
    }
    
    private func handleExitTap() {
        print("Exit button tapped")
        selectedButtonIndex = nil
        appModel.sessionController?.endGame()
    }
}

// MARK: - Reusable Button Component
struct ScenarioButton: View {
    let title: String
    let iconName: String
    let buttonType: MenuButtonType
    let horizontalPadding: CGFloat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            switch buttonType {
            case .standard:
                standardButtonContent
            case .debrief:
                debriefButtonContent
            case .exit:
                EmptyView() // Exit is handled separately in the parent view
            }
        }
        .background(buttonBackground)
        .cornerRadius(50)
    }
    
    // MARK: - Button Content Views
    private var standardButtonContent: some View {
        HStack(spacing: 2) {
            if isSelected {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .padding(.trailing, 1)
            }
            
            Text(title)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
        }
        .padding(EdgeInsets(
            top: isSelected ? 28 : 18,
            leading: horizontalPadding,
            bottom: isSelected ? 28 : 18,
            trailing: horizontalPadding
        ))
        .frame(alignment: .center)
    }
    
    private var debriefButtonContent: some View {
        HStack {
            VStack {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                
                if isSelected {
                    Text(title)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
            }
            .padding(isSelected ? 10 : 18)
        }
    }
    
    // MARK: - Button Background
    private var buttonBackground: some View {
        Group {
            if buttonType == .debrief {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(isSelected ? 0.6 : 0.3)
            } else {
                Color.blue.opacity(isSelected ? 0.9 : 0.5)
            }
        }
    }
}
