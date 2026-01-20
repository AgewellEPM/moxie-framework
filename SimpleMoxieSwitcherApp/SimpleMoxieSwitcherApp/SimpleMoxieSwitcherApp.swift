//
//  SimpleMoxieSwitcherApp.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI

@main
struct SimpleMoxieSwitcherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
    }
}