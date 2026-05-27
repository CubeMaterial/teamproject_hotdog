//
//  hotdogappApp.swift
//  hotdogapp
//
//  Created by 정진석 on 5/7/26.
//

import SwiftUI

@main
struct hotdogappApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
