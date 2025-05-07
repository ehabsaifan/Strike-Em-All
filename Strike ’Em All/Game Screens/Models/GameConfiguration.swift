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
    
    enum TimeMode: Hashable {
        case unlimited
        case limited
    }
    
    var player1: Player = defaultPlayer1
    var player2: Player?
    var soundCategory: SoundCategory = .street
    var wrapEnabled: Bool = false
    
    var timeMode: TimeMode = .unlimited
    var timeLimit: TimeInterval = 0
    
    let maxNumberOfRows = Array(1...6)
    let timeOptions: [TimeInterval] = [30, 60, 90, 120, 180, 240, 300]
       
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
    
    var timerEnabled: Bool = false {
        didSet {
            timeMode = timerEnabled ? .limited: .unlimited
            timeLimit = timerEnabled ? 120: 0
        }
    }
}
