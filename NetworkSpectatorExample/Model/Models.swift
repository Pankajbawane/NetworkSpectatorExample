//
//  Models.swift
//  NetworkSpectatorExample
//
//  Example app demonstrating NetworkSpectator framework for iOS/macOS
//  https://github.com/Pankajbawane/NetworkSpectator
//
//  Created by Pankaj Bawane on 21/02/26.
//

import Foundation

struct Character: Decodable, Identifiable {
    let url: String
    let name: String
    let gender: String
    let culture: String
    let born: String
    let died: String
    let titles: [String]
    let aliases: [String]
    let playedBy: [String]
    
    var id: String { url }
    
    var displayName: String {
        if !name.isEmpty {
            return name
        } else if let firstAlias = aliases.first, !firstAlias.isEmpty {
            return firstAlias
        } else {
            return "Unknown Character"
        }
    }
}
struct House: Decodable, Identifiable {
    let url: String
    let name: String
    let region: String
    let coatOfArms: String
    let words: String
    let titles: [String]
    let seats: [String]
    let founded: String
    let diedOut: String
    
    var id: String { url }
}

struct MockResponse: Decodable, Identifiable, Sendable {
    let response: String
    
    var id: String { response }
}

struct ImageItem: Decodable, Identifiable {
    let id: String
    let download_url: String
}
