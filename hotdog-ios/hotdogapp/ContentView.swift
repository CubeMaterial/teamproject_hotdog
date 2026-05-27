//
//  ContentView.swift
//  hotdogapp
//
//  Created by 정진석 on 5/7/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRouterView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
