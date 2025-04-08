//
//  ScoreManager.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation

protocol ScoreManagerProtocol {
    var player1Score: Int { get set }
    var player2Score: Int { get set }
    func updateScore(for player: Player, by points: Int)
    func resetScores()
}

class ScoreManager: ObservableObject, ScoreManagerProtocol {
    static let shared = ScoreManager()
    
    @Published var player1Score: Int {
        didSet {
            UserDefaults.standard.set(player1Score, forKey: "player1Score")
        }
    }
    
    @Published var player2Score: Int {
        didSet {
            UserDefaults.standard.set(player2Score, forKey: "player2Score")
        }
    }
    
    private init() {
        // Load saved scores; if none found, default to 0.
        self.player1Score = UserDefaults.standard.integer(forKey: "player1Score")
        self.player2Score = UserDefaults.standard.integer(forKey: "player2Score")
    }
    
    func updateScore(for player: Player, by points: Int) {
        switch player {
        case .player(let name) where name == "Player 1":
            player1Score += points
        case .player(let name) where name == "Player 2":
            player2Score += points
        default:
            break
        }
    }
    
    func resetScores() {
        player1Score = 0
        player2Score = 0
    }
}
