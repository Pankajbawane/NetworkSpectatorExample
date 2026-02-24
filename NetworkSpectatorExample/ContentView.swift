//
//  ContentView.swift
//  NetworkSpectatorExample
//
//  Example app demonstrating NetworkSpectator framework for iOS/macOS
//  https://github.com/Pankajbawane/NetworkSpectator
//  Features: HTTP request/response logging, mock responses, selective logging
//
//  Created by Pankaj Bawane on 17/12/25.
//

import SwiftUI
import NetworkSpectator

struct ContentView: View {
    
    @State private var viewModel = ViewModel()
    @State private var showLogs: Bool = false
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 10) {
                    Text("NetworkSpectator Example App")
                        .font(.headline)
                    
                    VStack(spacing: 6) {
                        Text("Monitor HTTP requests & responses in real-time. Features include logging, mocking, and selective request filtering.")
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Tap 'Call Services' to make HTTP requests. Tap 'Show Logs' to view NetworkSpectator UI.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button("Call Services") {
                            Task {
                                await viewModel.callServices()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Show Logs") {
                            #if os(macOS)
                            openWindow(id: "NetworkSpectator")
                            #else
                            showLogs.toggle()
                            #endif
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 5)
                    }
                }
                .padding()
                
                Divider()
                
                // Data Display Section
                if !viewModel.mockResponses.isEmpty || !viewModel.characters.isEmpty || !viewModel.houses.isEmpty || viewModel.skippedRequestCount > 0 {
                    List {
                        
                        // Skipped Requests Section
                        if viewModel.skippedRequestCount > 0 {
                            Section("Skipped Logging") {
                                Text("\(viewModel.skippedRequestCount) request(s) called which are skipped from logging")
                                    .font(.subheadline)
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Mock Responses Section
                        if !viewModel.mockResponses.isEmpty {
                            Section("Mock Responses") {
                                ForEach(viewModel.mockResponses) { mock in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mock Response")
                                            .font(.headline)
                                        
                                        Text(mock.response)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.top, 2)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        
                        // Characters Section
                        if !viewModel.characters.isEmpty {
                            Section("Characters (\(viewModel.characters.count))") {
                                ForEach(viewModel.characters.prefix(10)) { character in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(character.displayName)
                                            .font(.headline)
                                        
                                        if !character.culture.isEmpty {
                                            Text("Culture: \(character.culture)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if !character.titles.isEmpty, let firstTitle = character.titles.first, !firstTitle.isEmpty {
                                            Text(firstTitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        
                        // Houses Section
                        if !viewModel.houses.isEmpty {
                            Section("Houses (\(viewModel.houses.count))") {
                                ForEach(viewModel.houses.prefix(10)) { house in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(house.name)
                                            .font(.headline)
                                        
                                        if !house.region.isEmpty {
                                            Text("Region: \(house.region)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if !house.words.isEmpty {
                                            Text("\"\(house.words)\"")
                                                .font(.caption)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "network.slash",
                        description: Text("Press 'Call Services' to fetch data")
                    )
                }
            }
            .navigationTitle("NetworkSpectator")
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
