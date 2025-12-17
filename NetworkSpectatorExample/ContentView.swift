//
//  ContentView.swift
//  NetworkSpectatorExample
//
//  Created by Pankaj Bawane on 17/12/25.
//

import SwiftUI
import NetworkSpectator

struct ContentView: View {
    
    let viewModel = ViewModel()
    
    @State private var showLogs: Bool = false
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    var body: some View {
        VStack {
            Text("Hello, Network Spectator!")
                .padding(10)
            
            Button("Call Services") {
                Task {
                    await viewModel.callServices()
                }
            }
            .padding(10)
            
            Button("Show Logs") {
                #if os(macOS)
                // On Mac, open NetworkSpectator in a new window.
                openWindow(id: "NetworkSpectator")
                #else
                showLogs.toggle()
                #endif
            }
            .padding(10)
        }
        .onAppear {
            viewModel.skipLogging()
            viewModel.registerMock()
        }
        #if os(iOS)
        .sheet(isPresented: $showLogs) {
            NetworkSpectator.rootView
        }
        #endif
    }
}
