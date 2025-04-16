/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that presents debriefing information in a immersive space.
*/

import RealityKit
import RealityKitContent
import Spatial
import SwiftUI

struct DebriefView: View {
    @Environment(AppModel.self) var appModel
    
    // Define a constant for the entity identifier
    private let debriefContentID = "DebriefContent"
    
    var body: some View {
        RealityView { content, attachments in
            // Create a root entity
            let group = Entity()
            content.add(group)
            
             let sphere = ModelEntity(
                mesh: .generateSphere(radius: 0.1),
                materials: [SimpleMaterial(color: .red, isMetallic: false)])
            sphere.setPosition([-0.5, 0, 0], relativeTo: group)
            
            group.addChild(sphere)
            
        } update: { content, attachments in
            
        } attachments: {
            
        }
    }
} 
