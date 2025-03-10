//
//  Player.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

enum Player: Equatable {
    case player(name: String), computer
    
    var name: String {
        switch self {
        case .player(let name):
            return name
        case .computer:
            return "Computer"
        }
    }
}

func ==(lhs: Player, rhs: Player) -> Bool {
    lhs.name == rhs.name
}
