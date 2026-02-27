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
    var skippedRequestCount: Int = 0
    var isLoading: Bool = false
    var totalRequests: Int = 0
    var images: [ImageItem] = []
    var dataReceived: Bool {
        !characters.isEmpty || !houses.isEmpty || !images.isEmpty || !mockResponses.isEmpty || skippedRequestCount > 0
    }
    
    init() { }
    
    
    /// Calls HTTP services to  fetch data from servers.
    func callServices() async {
        // Call HTTP services to illustrate logging with NetworkSpectator.
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.makeRequestWithDefaultSession(urlString: "https://openlibrary.org/api/books?bibkeys=ISBN:0201558025,LCCN:93005405&format=json")
            }
            group.addTask {
                await self.makeRequestWithDefaultSession(urlString: "http://covers.openlibrary.org/b/isbn/0385472579-S.jpg")
            }
            
            group.addTask {
                await self.makeRequestWithDefaultSession(urlString: "http://some.unknown.url/for/intentional/error")
            }
            
            group.addTask {
                await self.makeRequestWithDefaultSession(urlString: "https://openlibrary.org/api/books?bibkeys=ISBN:0201558025,LCCN:93005405&format=json")
            }
            
            group.addTask {
                let result: Result<[ImageItem], Error> = await self.makeRequestWithConfiguration(urlString: "https://picsum.photos/v2/list?page=2&limit=5")
                switch result {
                case .success(let image):
                    await MainActor.run {
                        self.images.append(contentsOf: image)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
            group.addTask { @MainActor in
                if let url = URL(string: "https://mock.example.com/api/mock/1") {
                    let config = URLSessionConfiguration.default
                    let session = URLSession(configuration: config)
                    do {
                        let (data, _) = try await session.data(from: url)
                        let mockResponse = try JSONDecoder().decode(MockResponse.self, from: data)
                        self.mockResponses.append(mockResponse)
                    } catch {
                        print(error)
                    }
                }
            }
            
            group.addTask {
                let result: Result<[Character], Error> = await self.makeRequestWithConfiguration(urlString: "https://www.anapioficeandfire.com/api/characters")
                switch result {
                case .success(let chars):
                    await MainActor.run {
                        self.characters.append(contentsOf: chars)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
            group.addTask {
                let result: Result<[House], Error> = await self.makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/houses")
                switch result {
                case .success(let houses):
                    await MainActor.run {
                        self.houses.append(contentsOf: houses)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
            group.addTask {
                await self.makeRequestWithDefaultSession(urlString: "https://jsonplaceholder.typicode.com/users")
                await MainActor.run {
                    self.skippedRequestCount += 1
                }
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
    private func makeRequestWithConfiguration<T: Decodable>(urlString: String) async -> Result<T, Error> {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return .failure(URLError(.badURL))
        }
        totalRequests += 1
        let urlRequest = URLRequest(url: url)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        do {
            let result = try await session.data(for: urlRequest)
            let data = try JSONDecoder().decode(T.self, from: result.0)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    /// Makes a network request with Shared URLSession and decodes the response.
    /// - Parameter urlString: URL.
    private func makeRequestWithDefaultSession(urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        totalRequests += 1
        let urlRequest = URLRequest(url: url)
        do {
            _ = try await URLSession.shared.data(for: urlRequest)
        } catch {
            print(error)
        }
    }
    
    /// Makes a network request with Shared URLSession and Completion Handler and decodes the response.
    /// - Parameter urlString: URL.
    /// - Returns: Response.
    private func makeRequestWithCompletionHandler<T: Decodable>(urlString: String) async -> Result<T, Error> {
        await withCheckedContinuation { continuation in
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return continuation.resume(returning: .failure(URLError(.badURL)))
            }
            totalRequests += 1
            let urlRequest = URLRequest(url: url)
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                
                guard let data else { return }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    continuation.resume(returning: .success(decoded))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }.resume()
        }
    }
}
