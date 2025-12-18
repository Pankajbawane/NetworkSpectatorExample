//
//  NetworkSpectatorExampleApp.swift
//  NetworkSpectatorExample
//
//  Created by Pankaj Bawane on 17/12/25.
//

import SwiftUI
import NetworkSpectator

@main
struct NetworkSpectatorExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    NetworkSpectator.start()
                }
        }
        #if os(macOS)
        Window("Network Spectator", id: "NetworkSpectator") {
            NetworkSpectator.rootView
        }
        #endif
    }
}
