/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the welcome view.
*/

import SwiftUI

/// A view that introduces the Practice Together game, and invites the person to
/// create a SharePlay group session with the current FaceTime call.
///
/// ```
/// ┌───────────────────────────────────────┐
/// │                                       │
/// │               {   *   }               │
/// │                                       │
/// │           Practice Together!          │
/// │                                       │
/// │                                       │
/// │   Welcome! To play, join a FaceTime   │
/// │                call...                │
/// │              ┌─────────┐              │
/// │              │ Play  ▶ │              │
/// │              └─────────┘              │
/// └───────────────────────────────────────┘
/// ```
struct WelcomeView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack {
            WelcomeBanner().offset(y: 20)
            
            Text("Practice Together!").italic().font(.extraLargeTitle)
            
            Text("""
                Welcome to Practice Together! \
                To play, join a FaceTime call with a handful of friends. \
                You'll join a team and take turns trying to get your teammates \
                to guess your secret phrase.
                """
            )
            .multilineTextAlignment(.center)
            .padding()
            
            Divider()
            
            SharePlayButton("Play Practice Together", activity: PracticeTogetherActivity())
                .padding(.vertical, 20)
        }
        .padding(.horizontal)
    }
}

struct WelcomeBanner: View {
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "syringe.fill")
                .foregroundStyle(.cyan.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "stethoscope.circle.fill")
                .foregroundStyle(.yellow.gradient)
            Image(systemName: "heart.text.clipboard.fill")
                .foregroundStyle(.orange.gradient)
                .scaleEffect(x: -1)
            
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 170))
                .foregroundStyle(.red.gradient)
                .offset(y: -20)
            
            Image(systemName: "cross.case.fill")
                .foregroundStyle(.purple.gradient)
            Image(systemName: "thermometer.variable.and.figure.circle.fill")
                .foregroundStyle(.green.gradient)
                .scaleEffect(x: -1)
            Image(systemName: "ivfluid.bag")
                .foregroundStyle(.blue.gradient)
        }
        .font(.system(size: 50))
        .frame(maxHeight: .infinity)
    }
}
