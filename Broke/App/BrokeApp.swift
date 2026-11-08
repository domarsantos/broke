//
//  BrokeApp.swift
//  Broke
//
//  Created by Oz Tamir on 19/08/2024.
//

import SwiftUI

@main
struct BrokeApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            BrokerView()
                .environment(environment)
                .environment(environment.modeStore)
                .environment(environment.tagStore)
                .environment(environment.focusController)
                .task {
                    await environment.bootstrap()
                }
        }
    }
}
