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
                        .fontDesign(.monospaced)
                    
                    VStack(spacing: 6) {
                        Text("Monitor HTTP requests & responses in real-time. Features include intercepting, logging, mocking, selective request filtering and exporting.")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Tap 'Fetch Data' to make HTTP requests. Tap 'Show Logs' to launch NetworkSpectator UI.")
                            .font(.caption2)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button("Fetch Data") {
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
                }
                .padding()
                
                Divider()
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Text("HTTP requests count: \(viewModel.totalRequests)")
                        .font(Font.headline)
                }
                .padding(10)
                Divider()
                
                // Data Display Section
                if viewModel.dataReceived {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Characters Section
                            if !viewModel.characters.isEmpty {
                                sectionHeader("World of GoT - Characters (\(viewModel.characters.count))")
                                CardGridView(items: viewModel.characters, cardColor: .blue) { character in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(character.displayName)
                                            .font(.headline)
                                        if !character.culture.isEmpty {
                                            Text("Culture: \(character.culture)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        if !character.titles.isEmpty, let firstTitle = character.titles.first, !firstTitle.isEmpty {
                                            Text(firstTitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                            }
                            
                            // Houses Section
                            if !viewModel.houses.isEmpty {
                                sectionHeader("World of GoT - Houses (\(viewModel.houses.count))")
                                CardGridView(items: viewModel.houses, cardColor: .orange) { house in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(house.name)
                                            .font(.headline)
                                        if !house.region.isEmpty {
                                            Text("Region: \(house.region)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        if !house.words.isEmpty {
                                            Text("\"\(house.words)\"")
                                                .font(.caption)
                                                .italic()
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                            }
                            
                            // Skipped Requests Section
                            if viewModel.skippedRequestCount > 0 {
                                sectionHeader("Requests skipped from logging: \(viewModel.skippedRequestCount)")
                                CardGridView(items: viewModel.users, cardColor: .mint) { user in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Mock Responses Section
                            if !viewModel.mockResponses.isEmpty {
                                sectionHeader("Mock Responses")
                                CardGridView(items: viewModel.mockResponses, cardColor: .purple) { mock in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mock Response")
                                            .font(.headline)
                                        Text(mock.response)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Image Grid
                            if !viewModel.images.isEmpty {
                                sectionHeader("Images using AsyncImage - (\(viewModel.images.count))")
                                Text("Each AsyncImage fetchs images from the internet resulting in an HTTP request")
                                    .font(.footnote)
                                    .fontDesign(.monospaced)
                                    .padding(.horizontal)
                                
                                ImageGridView(images: viewModel.images)
                                    .frame(height: 300)
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "network.slash",
                        description: Text("Press 'Fetch Data' to fetch content")
                    )
                }
            }
            .navigationTitle("NetworkSpectator")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showLogs) {
            NetworkSpectator.rootView
        }
        #endif
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.horizontal)
    }


}
