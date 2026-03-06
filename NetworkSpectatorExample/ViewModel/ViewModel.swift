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
    
    /// Calls HTTP services to  fetch data from servers.
    func callServices() async {
        // Call HTTP services to illustrate logging with NetworkSpectator.
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let result: [Character] = try await self.makeRequestWithConfiguration(urlString: "https://www.anapioficeandfire.com/api/characters")
                    await MainActor.run {
                        self.characters.append(contentsOf: result)
                    }
                } catch { }
            }
            
            group.addTask {
                do {
                    let result: [House] = try await self.makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/houses")
                    await MainActor.run {
                        self.houses.append(contentsOf: result)
                    }
                } catch { }
            }
            
            group.addTask {
                do {
                    let result: [ImageItem] = try await self.makeRequestWithConfiguration(urlString: "https://picsum.photos/v2/list?page=2&limit=5")
                    await MainActor.run {
                        self.images.append(contentsOf: result)
                    }
                } catch { }
            }
            
            group.addTask {
                do {
                    let result: MockResponse = try await self.makeRequestWithConfiguration(urlString: "https://mock.example.com/api/mock/1")
                    await MainActor.run {
                        self.mockResponses.append(result)
                    }
                } catch { }
            }
            
            group.addTask {
                _ = try? await self.makeRawRequest(urlString: "http://some.unknown.url/for/intentional/error")
            }
            
            group.addTask {
                do {
                    let result: [User] = try await self.makeRequestWithDefaultSession(urlString: "https://jsonplaceholder.typicode.com/users")
                    await MainActor.run {
                        self.users.append(contentsOf: result)
                    }
                } catch { }
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
        let mockRule = MatchRule.url("https://mock.example.com/api/mock/1")
        do {
            let mock = try Mock(rule: mockRule, response: ["response": "this is a mock response"], statusCode: 200)
            NetworkSpectator.registerMock(for: mock)
        } catch {
            print("mock failed")
        }
    }
    
    /// Makes a network request with custom URLSession Configuration and decodes the response.
    /// - Parameter urlString: URL.
    /// - Returns: Response.
    private func makeRequestWithConfiguration<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let urlRequest = URLRequest(url: url)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        do {
            let result = try await session.data(for: urlRequest)
            let data = try JSONDecoder().decode(T.self, from: result.0)
            return data
        } catch {
            throw error
        }
    }
    
    /// Makes a network request with Shared URLSession and decodes the response.
    /// - Parameter urlString: URL.
    private func makeRequestWithDefaultSession<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let urlRequest = URLRequest(url: url)
        do {
            let result = try await URLSession.shared.data(for: urlRequest)
            let decoded = try JSONDecoder().decode(T.self, from: result.0)
            return decoded
        } catch {
            print(error)
            throw error
        }
    }
    
    /// Makes a network request with Shared URLSession and Completion Handler and decodes the response.
    /// - Parameter urlString: URL.
    /// - Returns: Response.
    private func makeRequestWithCompletionHandler<T: Decodable>(urlString: String) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return continuation.resume(throwing: URLError(.badURL))
            }
            
            let urlRequest = URLRequest(url: url)
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                guard let data else { return }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    continuation.resume(returning: decoded)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
    
    /// Makes a network request with Shared URLSession and decodes the response.
    /// - Parameter urlString: URL.
    private func makeRawRequest(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let urlRequest = URLRequest(url: url)
        do {
            let result = try await URLSession.shared.data(for: urlRequest)
            return result.0
        } catch {
            throw error
        }
    }
}
