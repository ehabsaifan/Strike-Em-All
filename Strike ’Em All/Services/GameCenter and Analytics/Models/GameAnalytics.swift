//
//  GameAnalytics.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/13/25.
//

import Foundation

struct GameAnalytics: Codable {
    var lifetimeTotalScore: Int = 0
    var lifetimeTotalTimePlayed: Double = 0
    var lifetimeCorrectShots: Int = 0
    var lifetimeMissedShots: Int = 0
    var lifetimeWinnings: Int = 0
    var lifetimeGamesPlayed: Int = 0
    var lifetimeLongestWinningStreak: Int = 0
    var currentWinningStreak: Int = 0
    var lastGameCorrectShots: Int = 0
    var lastGameMissedShots: Int = 0
    var lifetimePerfectGamesCount: Int = 0 
    var lifetimeLongestPerfectGamesStreak: Int = 0
    var achievementEarnedIDs: [String] = []
    var achievementEarnedDates: [Date] = []
    
    var accuracy: Double {
        let total = lifetimeCorrectShots + lifetimeMissedShots
        guard total > 0 else { return 0 }
        return Double(lifetimeCorrectShots) / Double(total)
    }

    var overAllAccuracy: String {
        guard accuracy > 0 else { return "0%" }
        return String(format: "%.0f%%", accuracy * 100)
    }
    
    var totalLost: Int {
        lifetimeGamesPlayed - lifetimeWinnings
    }
}
