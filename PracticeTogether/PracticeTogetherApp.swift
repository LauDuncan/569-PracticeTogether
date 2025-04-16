//
//  PracticeTogetherApp.swift
//  PracticeTogether
//
//  Created by Duncan Lau on 4/2/25.
//

import SwiftUI

@main
struct PracticeTogetherApp: App {

    @State var appModel = AppModel()

    var body: some Scene {
        Group {
            PracticeTogetherWindow()
            GameSpace()
            DebriefSpace()
        }
        .environment(appModel)
    }
}
