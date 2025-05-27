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
    /// Which high‐level variant
    var mode: GameMode = .classic

    /// Players
    var player1: Player
    var player2: Player?       // nil for single‐player

    /// Classic/rows
    var rowCount: Int = SimpleDefaults.getValue(forKey: .numberOfRows) ?? 5 {
        didSet { SimpleDefaults.setValue(rowCount, forKey: .numberOfRows) }
    }

    /// Dartboard / multiCircle
    var ringCount: Int = 4

    /// Persisting & multiCircle
    var ballsPerPlayer: Int = 1

    /// Timed mode
    var isTimed: Bool = false {
        didSet {
            timeMode = isTimed ? .limited : .unlimited
            if isTimed && timeLimit == 0 {
                timeLimit = timeOptions.first ?? 60
            }
            
            if !isTimed {
                timeLimit = 0
            }
        }
    }
    enum TimeMode { case unlimited, limited }
    var timeMode: TimeMode = .unlimited
    var timeLimit: TimeInterval = 0

    /// Shared options
    let timeOptions: [TimeInterval] = [30,60,120,180,240,300]
    var wrapEnabled: Bool = false
    var volume: Float = SimpleDefaults.getValue(forKey: .volumePref) ?? 1.0 {
        didSet { SimpleDefaults.setValue(volume, forKey: .volumePref) }
    }
    var soundCategory: SoundCategory = .street
    var rollingObjectType: RollingObjectType =
        SimpleDefaults.getEnum(forKey: .rollingObject) ?? .crumpledPaper {
        didSet { SimpleDefaults.setEnum(rollingObjectType, forKey: .rollingObject) }
    }

    init(player1: Player,
         player2: Player? = nil,
         mode: GameMode = .classic)
    {
        self.player1 = player1
        self.player2 = player2
        self.mode    = mode
    }
    let maxNumberOfRows = Array(1...6)
    
    mutating func swapPlayers() {
        guard let p2 = player2 else {
            return
        }
        player2 = player1
        player1 = p2
    }
}
