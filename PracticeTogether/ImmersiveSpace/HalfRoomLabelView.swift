import RealityKit
import RealityKitContent
import Spatial
import SwiftUI

struct HalfRoomLabelView: View {
    @Environment(AppModel.self) var appModel
    @State private var debugMessage = ""
    
    var body: some View {
        VStack {
            // RealityView { content in
            //     // Create a root entity
            //     let group = Entity()
            //     content.add(group)
            
            //     let sphere = ModelEntity(
            //         mesh: .generateSphere(radius: 0.1),
            //         materials: [SimpleMaterial(color: .red, isMetallic: false)])
            //     sphere.setPosition([0, 0, 0], relativeTo: group)
            
            //     group.addChild(sphere)
            
            //     print("First RealityView initialized")
            // }.frame(width: 200, height: 200)
            
            
            RealityView { content  in
                
                if let roomScene = try? await Entity(named: "HalfRoomLabels", in: realityKitContentBundle) {
                    content.add(roomScene)
                    
                    // Rename object in the RCP scene to be "Animated" if there's animation
                    if let animatedNurse = roomScene.findEntity(named: "NurseCPR") {
                        animatedNurse.name = "NurseCPR"
                        
                        if let animationResource = animatedNurse.availableAnimations.first {
                            let loopingAnimation = animationResource.repeat()
                            let animationController = animatedNurse.playAnimation(loopingAnimation, transitionDuration: 0.5)
                        } else {
                            print("No animation resource available on the animated object")
                        }
                    } else {
                        print("Animated object entity not found in the RCP scene")
                    }
                    
                    // Move the entire room further away from the origin
                    roomScene.position = SIMD3<Float>(0, 0, 0.1)
//                    roomScene.scale = SIMD3<Float>(1, 1, 1)
                }
            }.frame(width: 250, height: 250)
        }
        
    }
}
