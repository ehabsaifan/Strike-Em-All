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
    var currentPrefectWinningStreak: Int = 0
    var lastGameCorrectShots: Int = 0
    var lastGameMissedShots: Int = 0
    var lifetimePerfectGamesCount: Int = 0
    var lifetimeLongestPerfectGamesStreak: Int = 0
    var achievementEarnedIDs: [String] = []
    var achievementEarnedDates: [Date] = []
    
    // Computed
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
    
    // MARK: - Coding
    
    enum CodingKeys: String, CodingKey {
        case lifetimeTotalScore
        case lifetimeTotalTimePlayed
        case lifetimeCorrectShots
        case lifetimeMissedShots
        case lifetimeWinnings
        case lifetimeGamesPlayed
        case lifetimeLongestWinningStreak
        case currentWinningStreak
        case currentPrefectWinningStreak
        case lastGameCorrectShots
        case lastGameMissedShots
        case lifetimePerfectGamesCount
        case lifetimeLongestPerfectGamesStreak
        case achievementEarnedIDs
        case achievementEarnedDates
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lifetimeTotalScore               = try c.decodeIfPresent(Int.self,     forKey: .lifetimeTotalScore)            ?? 0
        lifetimeTotalTimePlayed          = try c.decodeIfPresent(Double.self,  forKey: .lifetimeTotalTimePlayed)       ?? 0
        lifetimeCorrectShots             = try c.decodeIfPresent(Int.self,     forKey: .lifetimeCorrectShots)          ?? 0
        lifetimeMissedShots              = try c.decodeIfPresent(Int.self,     forKey: .lifetimeMissedShots)           ?? 0
        lifetimeWinnings                 = try c.decodeIfPresent(Int.self,     forKey: .lifetimeWinnings)              ?? 0
        lifetimeGamesPlayed              = try c.decodeIfPresent(Int.self,     forKey: .lifetimeGamesPlayed)           ?? 0
        lifetimeLongestWinningStreak     = try c.decodeIfPresent(Int.self,     forKey: .lifetimeLongestWinningStreak)  ?? 0
        currentWinningStreak             = try c.decodeIfPresent(Int.self,     forKey: .currentWinningStreak)          ?? 0
        currentPrefectWinningStreak      = try c.decodeIfPresent(Int.self,     forKey: .currentPrefectWinningStreak)   ?? 0
        lastGameCorrectShots             = try c.decodeIfPresent(Int.self,     forKey: .lastGameCorrectShots)          ?? 0
        lastGameMissedShots              = try c.decodeIfPresent(Int.self,     forKey: .lastGameMissedShots)           ?? 0
        lifetimePerfectGamesCount        = try c.decodeIfPresent(Int.self,     forKey: .lifetimePerfectGamesCount)     ?? 0
        lifetimeLongestPerfectGamesStreak = try c.decodeIfPresent(Int.self,    forKey: .lifetimeLongestPerfectGamesStreak) ?? 0
        achievementEarnedIDs             = try c.decodeIfPresent([String].self, forKey: .achievementEarnedIDs)         ?? []
        achievementEarnedDates           = try c.decodeIfPresent([Date].self,   forKey: .achievementEarnedDates)       ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(lifetimeTotalScore,               forKey: .lifetimeTotalScore)
        try c.encode(lifetimeTotalTimePlayed,          forKey: .lifetimeTotalTimePlayed)
        try c.encode(lifetimeCorrectShots,             forKey: .lifetimeCorrectShots)
        try c.encode(lifetimeMissedShots,              forKey: .lifetimeMissedShots)
        try c.encode(lifetimeWinnings,                 forKey: .lifetimeWinnings)
        try c.encode(lifetimeGamesPlayed,              forKey: .lifetimeGamesPlayed)
        try c.encode(lifetimeLongestWinningStreak,     forKey: .lifetimeLongestWinningStreak)
        try c.encode(currentWinningStreak,             forKey: .currentWinningStreak)
        try c.encode(currentPrefectWinningStreak,      forKey: .currentPrefectWinningStreak)
        try c.encode(lastGameCorrectShots,             forKey: .lastGameCorrectShots)
        try c.encode(lastGameMissedShots,              forKey: .lastGameMissedShots)
        try c.encode(lifetimePerfectGamesCount,        forKey: .lifetimePerfectGamesCount)
        try c.encode(lifetimeLongestPerfectGamesStreak,forKey: .lifetimeLongestPerfectGamesStreak)
        try c.encode(achievementEarnedIDs,             forKey: .achievementEarnedIDs)
        try c.encode(achievementEarnedDates,           forKey: .achievementEarnedDates)
    }
}
