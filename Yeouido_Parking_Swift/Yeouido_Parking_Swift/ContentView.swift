//
//  ContentView.swift
//  Yeouido_Parking_Swift
//
//  Created by MAC on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var globalState: GlobalState

    var body: some View {
        Group {
            if globalState.userLoginStatus {
                MainView()
            } else {
                MainView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GlobalState())
    }
}
