//
//  Player.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

struct Player: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var type: PlayerType
    var lastUsed: Date
    
    init(id: String = UUID().uuidString, name: String, type: PlayerType, lastUsed: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.lastUsed = lastUsed
    }
}

func ==(lhs: Player, rhs: Player) -> Bool {
    lhs.id == rhs.id && lhs.name == rhs.name
}

let computer = Player(id: "Computer", name: "Computer", type: .guest)
