import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Button Model
struct MenuButtonModel: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let buttonType: MenuButtonType
    let horizontalPadding: (normal: CGFloat, selected: CGFloat)
    var isSelected: Bool = false
}

// MARK: - Button Types
enum MenuButtonType {
    case standard
    case debrief
    case exit
}

// MARK: - Content View
struct SceneSwitchView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.physicalMetrics) var converter

    // State to track the currently selected button
    @State private var selectedButtonIndex: Int? = nil
    
    // Main buttons data
    @State private var menuButtons: [MenuButtonModel] = [
        MenuButtonModel(title: "Provide Oxygen", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: (70, 70)),
        MenuButtonModel(title: "Place Defibrillator Pads", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: (35, 35)),
        MenuButtonModel(title: "Set Defibrillation Energy", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: (35, 35)),
        MenuButtonModel(title: "Provide Defib Shock", iconName: "arrow.clockwise", buttonType: .standard, horizontalPadding: (50, 50)),
        MenuButtonModel(title: "Debrief Room", iconName: "bubble.left.and.bubble.right.fill", buttonType: .debrief, horizontalPadding: (0, 0))
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Main menu buttons
            ForEach(0..<menuButtons.count, id: \.self) { index in
                MenuButton(
                    model: $menuButtons[index],
                    isSelected: menuButtons[index].isSelected,
                    action: {
                        selectButton(at: index)
                    }
                )
            }
            
            // Exit Button
            Button(action: {
                print("Exit Button tapped")
                // Deselect all other buttons
                deselectAllButtons()
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
    
    // MARK: - Button Selection Logic
    private func selectButton(at index: Int) {
        // Deselect all buttons
        deselectAllButtons()
        
        // Select the tapped button
        menuButtons[index].isSelected = true
        selectedButtonIndex = index
    }
    
    private func deselectAllButtons() {
        for i in 0..<menuButtons.count {
            menuButtons[i].isSelected = false
        }
        selectedButtonIndex = nil
    }
}

// MARK: - Reusable Button Component
struct MenuButton: View {
    @Binding var model: MenuButtonModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            switch model.buttonType {
            case .standard:
                standardButtonContent
            case .debrief:
                debriefButtonContent
            case .exit:
                EmptyView() // Exit button is handled separately
            }
        }
        .background(buttonBackground)
        .cornerRadius(50)
    }
    
    // MARK: - Button Content Views
    private var standardButtonContent: some View {
        HStack(spacing: 2) {
            if isSelected {
                Image(systemName: model.iconName)
                    .foregroundColor(.white)
                    .padding(.trailing, 1)
            }
            
            Text(model.title)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
        }
        .padding(EdgeInsets(
            top: isSelected ? 28 : 18,
            leading: model.horizontalPadding.normal,
            bottom: isSelected ? 28 : 18,
            trailing: model.horizontalPadding.normal
        ))
        .frame(alignment: .center)
    }
    
    private var debriefButtonContent: some View {
        HStack {
            VStack {
                Image(systemName: model.iconName)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                
                if isSelected {
                    Text(model.title)
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
            if model.buttonType == .debrief {
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


//#Preview(windowStyle: .automatic) {
//    SceneSwitchView()
//        .environment(AppModel())
//}
    
