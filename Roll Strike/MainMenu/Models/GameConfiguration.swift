//
//  GameConfiguration.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/16/25.
//

import Foundation

let defaultPlayer1 = Player(name: "Player 1", type: .guest)
let defaultPlayer2 = Player(name: "Player 2", type: .guest)

struct GameConfiguration {
    var playerMode: PlayerMode = .singlePlayer {
        didSet {
            switch playerMode {
            case .againstComputer:
                player2 = computer
            case .singlePlayer,
                    .twoPlayers:
                player2 = nil
            }
        }
    }
    var player1: Player = defaultPlayer1
    var player2: Player?
    var soundCategory: SoundCategory = .street
    var wrapEnabled: Bool = false
    var timed: Bool = false
    
    let maxNumberOfRows = Array(1...6)
       
    var rollingObjectType: RollingObjectType = SimpleDefaults.getEnum(forKey: .rollingObject) ?? .crumpledPaper {
        didSet {
            SimpleDefaults.setEnum(rollingObjectType, forKey: .rollingObject)
        }
    }
    
    var rowCount: Int = SimpleDefaults.getValue(forKey: .numberOfRows) ?? 5 {
        didSet {
            SimpleDefaults.setValue(rowCount, forKey: .numberOfRows)
        }
    }
    
    var volume: Float = SimpleDefaults.getValue(forKey: .volumePref) ?? 1.0 {
        didSet {
            SimpleDefaults.setValue(volume, forKey: .volumePref)
        }
    }
}
