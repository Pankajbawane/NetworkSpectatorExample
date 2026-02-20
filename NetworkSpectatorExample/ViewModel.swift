//
//  ViewModel.swift
//  NetworkSpectatorExample
//
//  Created by Pankaj Bawane on 17/12/25.
//

import Foundation
import NetworkSpectator

class ViewModel {
    
    init() { }
    
    func callServices() async {
        // Call HTTP services to illustrate logging.
        
        makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/characters")
        makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/houses")
        
        // This request will be ingored for logging. This illustrate Skip logging HTTP request.
        makeRequestWithCompletionHandler(urlString: "https://www.anapioficeandfire.com/api/ignore-this-one")
        
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
            
            group.addTask {
                // Mock example. This request will be mocked and return mocked response {"response": "this is a mock response"}.
                await self.makeRequest(urlString: "https://mock.example.com/api/mock/1")
            }
        }
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
    
    func makeRequest(urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        do {
            let result = try await session.data(for: urlRequest)
            print("Received response for URL: ", urlString,
                  " status code: ", (result.1 as? HTTPURLResponse)?.statusCode ?? 0)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func makeRequestWithCompletionHandler(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            print("Received response for URL: ", urlString,
                  " status code: ", (response as? HTTPURLResponse)?.statusCode ?? 0)
        }.resume()
    }
}
