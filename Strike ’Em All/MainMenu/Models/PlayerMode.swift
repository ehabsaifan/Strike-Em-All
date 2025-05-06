//
//  PlayerMode.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

enum PlayerMode: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case singlePlayer
    case twoPlayers
    case againstComputer
    
    var title: String {
        switch self {
        case .singlePlayer:
            "Single Player"
        case .twoPlayers:
            "Two Players"
        case .againstComputer:
            "Vs Computer"
        }
    }
}
