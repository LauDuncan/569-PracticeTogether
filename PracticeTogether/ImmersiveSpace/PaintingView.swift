/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that starts a new painting session, integrates SharePlay, and handles hand tracking with drag gestures.
*/

import SwiftUI
import RealityKit
import ARKit
import GroupActivities // Needed for SharePlay

/// A view that contains the `PaintingHandTracking` class and
/// the reality view, which creates a stroke mesh when a person uses the drag gesture.
struct PaintingView: View {
    // MARK: - State Properties
    @StateObject var paintingHandTracking = PaintingHandTracking()
    @Environment(AppModel.self) var appModel
    
    // Canvas is now dependent on the session controller, initialize lazily or in .onAppear
    @State var canvas: PaintingCanvas? 
    
    // State for managing the immersive space and SharePlay activation
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    // Computed property to access session controller
    private var sessionController: SessionController? {
        appModel.sessionController
    }

    var body: some View {
        RealityView { content in
            // Initialize canvas here if not already done
            if canvas == nil, let sessionController = sessionController {
                canvas = PaintingCanvas(sessionController: sessionController)
            }
            guard let canvas = canvas else { return }
            
            // Add the canvas root entity to the scene
            content.add(canvas.root)
            
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity() // Target gestures to the canvas collision boxes
                .onChanged { value in
                    guard let canvas = canvas else { return }
                    // Use pinch state from the hand tracking observable object
                    if paintingHandTracking.isPinching, let pose = paintingHandTracking.pinchLocation {
                        // If this is the start of a new pinched drag, begin the stroke
                        if canvas.currentLocalStrokeID == nil { 
                             canvas.startLocalStroke()
                        }
                        // Add point to the *local* stroke
                        canvas.addPointToLocalStroke(pose)
                    } else {
                         // If not pinching but dragging, ensure any active local stroke is finished
                         if canvas.currentLocalStrokeID != nil {
                            canvas.finishLocalStroke()
                         }
                    }
                }
                .onEnded { value in
                    // Finish the local stroke when the drag ends, regardless of pinch state
                    guard let canvas = canvas else { return }
                     if canvas.currentLocalStrokeID != nil {
                        canvas.finishLocalStroke()
                     }
                }
        )
        // Overlay for UI elements (like participant count)
        .overlay(alignment: .top) {
             if let session = sessionController?.session {
                 Text("Drawing with \(session.activeParticipants.count) people")
                     .padding()
                     .background(.regularMaterial)
                     .cornerRadius(8)
                     .padding(.top, 40)
             }
         }
        .overlay(alignment: .bottom) {
            Button("Exit Drawing Mode") {
                // Exit drawing mode and return to regular game mode
                sessionController?.exitDrawingMode()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .task {
            // Start hand tracking when the view appears.
            await paintingHandTracking.startTracking()
        }
        .onDisappear {
            // Stop hand tracking when the view disappears
            paintingHandTracking.stopTracking()
        }
    }
}

//// Preview needs adjustment if it relies on specific initializers now
//#Preview {
//     PaintingView()
//         // Add environment objects if needed for preview
//         // .environment(AppModel())
//}

