/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view of a podium the game presents in its immersive space, which positions the current
  secret phrase in front of the active player.
*/

import RealityKit
import RealityKitContent
import Spatial
import SwiftUI

struct ScenarioManagementView: View {
    @Environment(AppModel.self) var appModel
    
    // Define a constant for the entity identifier
    private let sceneSwitchViewID = "SceneSwitchView"
    
    var body: some View {
        RealityView { content, attachments  in

            if let roomScene = try? await Entity(named: "MedicalRoom", in: realityKitContentBundle) {
                content.add(roomScene)
            }

            if let switchViewEntity = attachments.entity(for: sceneSwitchViewID) {
                // Add a custom attribute to easily identify this entity later
                switchViewEntity.components.set(
                    EntityIDComponent(id: sceneSwitchViewID)
                )
                content.add(switchViewEntity)
            }

        } update: { content, attachments in
            if let sceneSwitchEntity = content.entities.first(where: { entity in
                return entity.components[EntityIDComponent.self]?.id == sceneSwitchViewID
            }) {
                updatePodiumPose(sceneSwitchEntity)
            }
        } attachments: {
            Attachment(id: sceneSwitchViewID) {
                SceneSwitchView()
            }
        }
        .frame(depth: 0)
    }
    
    func updatePodiumPose(_ phraseDeckPodium: Entity) {
        let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
        phraseDeckPodium.position = .init(podiumPosition)
    }
}

// Custom component to identify entities
struct EntityIDComponent: Component {
    var id: String
}
