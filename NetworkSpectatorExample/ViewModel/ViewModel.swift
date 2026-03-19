//
//  ViewModel.swift
//  NetworkSpectatorExample
//
//  Example app demonstrating NetworkSpectator framework for iOS/macOS
//  https://github.com/Pankajbawane/NetworkSpectator
//  Features: HTTP request/response logging, mock responses, selective logging
//
//  Created by Pankaj Bawane on 17/12/25.
//

import Foundation
import NetworkSpectator

@Observable
class ViewModel {
    
    var characters: [Character] = []
    var houses: [House] = []
    var mockResponses: [MockResponse] = []
    var isLoading: Bool = false
    var images: [ImageItem] = []
    var users: [User] = []
    var dataReceived: Bool {
        !characters.isEmpty || !houses.isEmpty || !images.isEmpty || !mockResponses.isEmpty || !users.isEmpty
    }
    
    init() {
        skipLogging()
        registerMock()
    }
    
    /// Calls HTTP services to fetch data from servers.
    func callServices() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchAndAssign("https://www.anapioficeandfire.com/api/characters") { self.characters = $0 }
            }
            group.addTask {
                await self.fetchAndAssign("https://www.anapioficeandfire.com/api/houses") { self.houses = $0 }
            }
            group.addTask {
                await self.fetchAndAssign("https://picsum.photos/v2/list?page=2&limit=5") { self.images = $0 }
            }
            group.addTask {
                await self.fetchAndAssign("https://mock.example.com/api/mock/1") { self.mockResponses = [$0] }
            }
            group.addTask {
                // Intentional error request to demonstrate error logging
                _ = try? await self.fetch(from: "http://some.unknown.url/for/intentional/error") as Data
            }
            group.addTask {
                await self.fetchAndAssign("https://jsonplaceholder.typicode.com/users") { self.users = $0 }
            }
        }
        
        isLoading = false
    }
    
    /// Example to skip logging HTTP request.
    func skipLogging() {
        let rule = MatchRule.url("https://jsonplaceholder.typicode.com/users")
        NetworkSpectator.ignoreLogging(for: rule)
    }
    
    /// Example to mock HTTP request.
    func registerMock() {
        let matchRule = MatchRule.url("https://mock.example.com/api/mock/1")
        do {
            let mock = try Mock(rule: matchRule, response: ["response": "this is a mock response"], statusCode: 500)
            NetworkSpectator.registerMock(for: mock)
        } catch {
            print("mock failed")
        }
    }
    
    /// Fetches, decodes, and assigns the result to a property on the MainActor.
    private func fetchAndAssign<T: Decodable>(_ urlString: String, assign: @MainActor @Sendable (T) -> Void) async {
        guard let result: T = try? await fetch(from: urlString) else { return }
        await MainActor.run { assign(result) }
    }
    
    /// Makes a network request and decodes the response.
    private func fetch<T: Decodable>(from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(T.self, from: data)
    }
}
