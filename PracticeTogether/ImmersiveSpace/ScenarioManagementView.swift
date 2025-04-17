/*
See the LICENSE.txt file for this sample's licensing information.

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
    
    // Track the active scene number (1-4)
    @State private var activeSceneNumber: Int = 1
    
    // Dictionary to store scene entities
    @State private var sceneEntities: [String: Entity] = [:]
    
    // Store the root scene for access in methods
    @State private var rootScene: Entity?
    
    // Track audio entity
    @State private var audioEntity: Entity?
    
    var body: some View {
        RealityView { content, attachments  in

            if let roomScene = try? await Entity(named: "SceneAll", in: realityKitContentBundle) {
                content.add(roomScene)
                
                // Store the root scene for later access
                rootScene = roomScene
                
                print("Successfully loaded SceneAll model")
                
                // Find and store all scene child entities
                for i in 1...4 {
                    let sceneName = "scene\(i)"
                    if let sceneEntity = roomScene.findEntity(named: sceneName) {
                        sceneEntities[sceneName] = sceneEntity
                        print("Found \(sceneName)")
                        
                        // Only enable the first scene initially
                        sceneEntity.isEnabled = (i == 1)
                    } else {
                        print("Could not find \(sceneName) in the model")
                    }
                }

                // Find ambient audio entity
                audioEntity = roomScene.findEntity(named: "AmbientAudio")
                let ambientAudioFileName = "/Root/SFX/hospital_ambience"

                guard let resource = try? await AudioFileResource(named: ambientAudioFileName, 
                    from: "SceneAll.usda", in: realityKitContentBundle) else {
                        print("Failed to load audio resource")
                    }

                let audioController = audioEntity?.prepareAudio(resource)
                audioController?.play()


                if audioEntity != nil {
                    
                } else {
                    print("AmbientAudio entity not found")
                }

                // Initial animation for the first scene
                animateNurseInScene(sceneNumber: 1)
                
                // Move the entire room further away from the origin
                roomScene.position = SIMD3<Float>(0, 0, 0)
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
                SceneSwitchView(activateScene: activateScene)
            }
        }
        .frame(depth: 0)
    }
    
    // Method to find ambient audio entity
    func findAmbientAudio() {
        guard let roomScene = rootScene else {
            print("Root scene not available for audio search")
            return
        }
        
        // Try to find AmbientAudio entity at root level
        // audioEntity = roomScene.findEntity(named: "AmbientAudio")
        // let ambientAudioFileName = "/Root/SFX/hospital_ambience"

        // guard let resource = try? await AudioFileResource(named: ambientAudioFileName, 
        //     from: "SceneAll.usda", in: realityKitContentBundle) else {
        //         print("Failed to load audio resource")
        //     }

        // let audioController = audioEntity?.prepareAudio(resource)
        // audioController?.play()


        // if audioEntity != nil {
            
        // } else {
        //     print("AmbientAudio entity not found")
        // }
    }
    
    // // Helper method to enable audio on an entity
    // func enableEntityAudio(_ entity: Entity) {
    //     print("Attempting to enable audio on \(entity.name)")
        
    //     // Get component names using reflection
    //     let mirror = Mirror(reflecting: entity.components)
    //     for child in mirror.children {
    //         if let componentName = child.label, componentName.contains("Audio") {
    //             print("Found audio component on \(entity.name): \(componentName)")
                
    //             // Make sure the entity is enabled so audio can play
    //             entity.isEnabled = true
    //             break
    //         }
    //     }
        
    //     // Check if this is an AudioEntity specifically
    //     let entityDescription = String(describing: type(of: entity))
    //     if entityDescription.contains("Audio") {
    //         print("Entity \(entity.name) appears to be an audio entity type: \(entityDescription)")
    //         entity.isEnabled = true
    //     }
        
    //     // Enable all child entities too, one might contain the audio
    //     for child in entity.children {
    //         enableEntityAudio(child)
    //     }
    // }
    
    // Method to animate the nurse in the current scene
    func animateNurseInScene(sceneNumber: Int) {
        guard let roomScene = rootScene else {
            print("Root scene not available")
            return
        }
        
        // Build the path to find the nurse in the current scene
        let sceneName = "scene\(sceneNumber)"
        
        // Try to find the nurse within the specified scene first
        var nurseToAnimate: Entity?
        if let sceneEntity = sceneEntities[sceneName] {
            // For scene 4, try to find Nurse_CPR_pressing first, then Nurse_standing
            if sceneNumber == 4 {
                nurseToAnimate = sceneEntity.findEntity(named: "Nurse_CPR_pressing")
                print("Looking for Nurse_CPR_pressing in \(sceneName)")
                
                // If Nurse_CPR_pressing not found, try Nurse_standing
                if nurseToAnimate == nil {
                    nurseToAnimate = sceneEntity.findEntity(named: "Nurse_Standing")
                    print("Nurse_CPR_pressing not found, looking for Nurse_Standing in \(sceneName)")
                }
            } else {
                nurseToAnimate = sceneEntity.findEntity(named: "Nurse_CPR_pressing")
                print("Looking for Nurse_CPR_pressing in \(sceneName)")
            }
        } 
        
        else {
            // Fallback to searching in the root scene
            nurseToAnimate = roomScene.findEntity(named: "Nurse_CPR_pressing")
            print("Looking for Nurse_CPR_pressing in root scene")
            
            // For scene 4, also check for Nurse_standing in the root if needed
            if sceneNumber == 4 && nurseToAnimate == nil {
                nurseToAnimate = roomScene.findEntity(named: "Nurse_Standing")
                print("Nurse_CPR_pressing not found in root, looking for Nurse_Standing")
            }
        }
        
        // Animate the nurse if found
        if let animatedNurse = nurseToAnimate {
            let nurseName = animatedNurse.name
            print("Found \(nurseName) entity")
            
            if let animationResource = animatedNurse.availableAnimations.first {
                let loopingAnimation = animationResource.repeat()
                let animationController = animatedNurse.playAnimation(loopingAnimation, transitionDuration: 0.5)
                print("Started animation on \(nurseName)")
            } else {
                print("No animation resource available on \(nurseName)")
            }
        } else {
            print("No nurse entity found to animate")
        }
    }
    
    // Method to activate a specific scene by number (1-4)
    func activateScene(number: Int) {
        guard number >= 1 && number <= 4 else { return }
        
        // Disable current active scene
        if let currentScene = sceneEntities["scene\(activeSceneNumber)"] {
            currentScene.isEnabled = false
        }
        
        // Enable new scene
        if let newScene = sceneEntities["scene\(number)"] {
            newScene.isEnabled = true
            activeSceneNumber = number
            print("Activated scene \(number)")
            
            // Animate nurse in the newly activated scene
            animateNurseInScene(sceneNumber: number)
            
            // // Find and re-enable audio for the new scene
            // if let audio = audioEntity {
            //     enableEntityAudio(audio)
            // }
        } else {
            print("Failed to activate scene \(number): Entity not found")
        }
    }
    
    func updatePodiumPose(_ phraseDeckPodium: Entity) {
        // Position the podium further away from the player
        // Original was just 0.6 units along x-axis
        let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
        phraseDeckPodium.position = .init(podiumPosition)
    }
}

// Custom component to identify entities
struct EntityIDComponent: Component {
    var id: String
}
