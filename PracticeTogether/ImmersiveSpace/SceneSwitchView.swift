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
}

// MARK: - Button Types
enum MenuButtonType {
    case standard
    case debrief
    case exit
}

// MARK: - Content View
struct SceneSwitchView: View {
<<<<<<< Updated upstream
    @Environment(\.physicalMetrics) var converter
    @Environment(AppModel.self) var appModel
    
    // Single source of truth for which button is currently selected
    @State private var selectedButtonIndex: Int? = nil
    
    // Define all buttons in a single array
    private let menuButtons: [MenuButtonModel] = [
        MenuButtonModel(title: "Provide Oxygen", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 70),
        MenuButtonModel(title: "Place Defibrillator Pads", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 35),
        MenuButtonModel(title: "Set Defibrillation Energy", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 35),
        MenuButtonModel(title: "Provide Defib Shock", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: 50),
        MenuButtonModel(title: "Debrief Room", iconName: "bubble.left.and.bubble.right.fill", buttonType: .debrief, horizontalPadding: 0)
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
=======
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        ZStack {
            // Get game state from the session controller or fallback to a default state
            switch appModel.sessionController?.game.stage {
            case .drawing:
                PaintingView()
            case .inGame:
                let gameSpace = appModel.sessionController?.game
                    .stage.isInGame == true
                
                ScenarioView()
                    .opacity(gameSpace ? 1 : 0)
            default:
                Text("No active scenario")
                    .font(.largeTitle)
>>>>>>> Stashed changes
            }
        }
    }
}

private struct ScenarioView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        HStack(spacing: 50) {
            nurseView
            defibrillatorView
            defibNurseView
            computerView
            
<<<<<<< Updated upstream
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
=======
            VStack(spacing: 0) {
                patientsHeadView
                patientView
>>>>>>> Stashed changes
            }
        }
    }
    
<<<<<<< Updated upstream
    // MARK: - Button Action Handlers
    private func handleButtonTap(at index: Int) {
        // Toggle selection state - if tapping the same button, it stays selected
        selectedButtonIndex = index
        
        // Perform the appropriate action based on the button type
        let button = menuButtons[index]
        switch button.buttonType {
        case .standard:
            print("Standard action button tapped: \(button.title)")
            // Add specific action logic here
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
=======
    var nurseView: some View {
        ScenarioItemView(
            scenarioName: "Airway Nurse",
            description: "Intubation, mask ventilation, suction, jaw thrust"
        )
    }
    
    var defibrillatorView: some View {
        ScenarioItemView(
            scenarioName: "Defibrillator",
            description: "Shock patient here when physician says ",clear,""
        )
    }
    
    var defibNurseView: some View {
        ScenarioItemView(
            scenarioName: "Defibrillator Nurse",
            description: "Monitors patient in defibrillator app, times chest compressions"
        )
    }
    
    var computerView: some View {
        ScenarioItemView(
            scenarioName: "Computer",
            description: "Code documentation, orders, med dosing"
        )
    }
    
    var patientsHeadView: some View {
        ScenarioItemView(
            scenarioName: "Patient's Head",
            description: "Airway nurse intubates"
        )
    }
    
    var patientView: some View {
        ScenarioItemView(
            scenarioName: "Patient",
            description: "Central line placement, chest compressions, monitors, IV"
        )
    }
}

private struct ScenarioItemView: View {
    var scenarioName: String
    var description: String
    
    var body: some View {
        VStack {
            Text(scenarioName)
                .font(.largeTitle)
                .fontWidth(.expanded)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: 400)
                .multilineTextAlignment(.center)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.regularMaterial)
                }
            
            Spacer()
                .frame(height: 40)
            
            Text(description)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: 400)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.regularMaterial)
                }
        }
>>>>>>> Stashed changes
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
