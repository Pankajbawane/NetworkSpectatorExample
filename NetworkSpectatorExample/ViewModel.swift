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
    
    init() { }
    
    func callServices() async {
        // Call HTTP services to illustrate logging with NetworkSpectator.
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.makeRequest(urlString: "https://openlibrary.org/api/books?bibkeys=ISBN:0201558025,LCCN:93005405&format=json")
            }
            group.addTask {
                await self.makeRequest(urlString: "http://covers.openlibrary.org/b/isbn/0385472579-S.jpg")
            }
            group.addTask {
                await self.makeRequest(urlString: "http://some.unknown.url/for/intentional/error")
            }
            
            group.addTask {
                await self.makeRequest(urlString: "http://some.unknown.url/for/intentional/error")
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
                let result: Result<[Character], Error> = await self.makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/characters")
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
                await self.makeRequest(urlString: "https://www.anapioficeandfire.com/api/ignore-this-one")
                await MainActor.run {
                    self.skippedRequestCount += 1
                }
            }
        }
        
        isLoading = false
    }
    
    // Example to skip logging HTTP request.
    func skipLogging() {
        let rule = MatchRule.url("https://www.anapioficeandfire.com/api/ignore-this-one")
        NetworkSpectator.ignoreLogging(for: rule)
    }
    
    // Example to mock HTTP request.
    func registerMock() {
        let mockRule = MatchRule.url("https://mock.example.com/api/mock/1")
        do {
            let mock = try Mock(rule: mockRule, response: ["response": "this is a mock response"], statusCode: 200)
            NetworkSpectator.registerMock(for: mock)
        } catch {
            print("mock failed")
        }
    }
    
    func makeRequest<T: Decodable>(urlString: String) async -> Result<T, Error> {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return .failure(URLError(.badURL))
        }
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
    
    func makeRequest(urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        do {
            _ = try await session.data(for: urlRequest)
        } catch {
            print(error)
        }
    }
    
    func makeRequestWithCompletionHandler<T: Decodable>(urlString: String) async -> Result<T, Error> {
        await withCheckedContinuation { continuation in
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return continuation.resume(returning: .failure(URLError(.badURL)))
            }
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
