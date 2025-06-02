//
//  GameResultInfo.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 5/4/25.
//

import Foundation

struct PlayerResultInfo: Codable {
    let player: Player
    let score: Score
    let correctShots: Int
    let missedShots: Int
    
    var correctShotsDesc: String {
        "\(correctShots)"
    }
    
    var missedShotsDesc: String {
        "\(missedShots)"
    }
            
    var accuracy: Double {
        let total = correctShots + missedShots
        guard total > 0 else { return 0 }
        return Double(correctShots) / Double(total)
    }
}

struct GameResultInfo: Codable, Identifiable {
    var id = UUID().uuidString
    let endState: GameViewConstants.EndState
    let timePlayed: TimeInterval
    let player1Info: PlayerResultInfo
    let player2Info: PlayerResultInfo?
    
    var player1Accuracy: Double {
        player1Info.accuracy
    }
    
    var player2Accuracy: Double? {
        player2Info?.accuracy
    }
}
