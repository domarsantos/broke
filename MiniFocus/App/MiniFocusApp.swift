//
//  MiniFocusApp.swift
//  MiniFocus
//
//  Created by Oz Tamir on 19/08/2024.
//

import SwiftUI

@main
struct MiniFocusApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(environment.modeStore)
                .environment(environment.tagStore)
                .environment(environment.focusController)
                .tint(MiniColor.primary)
                .preferredColorScheme(.light)
                .task {
                    await environment.bootstrap()
                }
        }
    }
}
