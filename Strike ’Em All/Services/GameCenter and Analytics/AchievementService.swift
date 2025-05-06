//
//  AchievementService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/12/25.
//

import Foundation

protocol AchievementServiceProtocol {
    /// Call this when the game ends to check and report any earned achievements.
    func updateAchievements(totalWins: Int,
                            currentStreak: Int,
                            finalScore: Int,
                            totalGames: Int,
                            totaleTime: Double,
                            perfectGames: Int,
                            perfectStreak: Int,
                            accuracy: Double)
}

class AchievementService: ObservableObject, AchievementServiceProtocol {
    static let shared = AchievementService()
    private init() {}
    
    func updateAchievements(totalWins: Int,
                            currentStreak: Int,
                            finalScore: Int,
                            totalGames: Int,
                            totaleTime: Double,
                            perfectGames: Int,
                            perfectStreak: Int,
                            accuracy: Double) {
        print("Reporting achievements. totalWins: \(totalWins) | currentStreak: \(currentStreak) | finalScore: \(finalScore)")
        
        // Wins
        if totalWins >= 1 {
            report(.firstWin)
        }
        if totalWins >= 5 {
            report(.fiveWins)
        }
        if totalWins >= 25 {
            report(.twintyFiveWins)
        }
        
        // Wins Streak
        if currentStreak >= 5 {
            report(.fiveWinsStreak)
        }
        if currentStreak >= 10 {
            report(.tenWinsStreak)
        }
        
        // Games Played
        if totalGames >= 1 {
            report(.firstGame)
        }
        if totalGames >= 10 {
            report(.tenGamesPlayed)
        }
        if totalGames >= 50 {
            report(.fiftyGamesPlayed)
        }
        if totalGames >= 100 {
            report(.oneHundredGamesPlayed)
        }
        
        // Perfect Games Played
        if perfectGames >= 1 {
            report(.firstPerfectGame)
        }
        if perfectGames >= 5 {
            report(.fivePerfectGames)
        }
        if perfectStreak >= 10 {
            report(.tenPerfectGamesStreak)
        }
        
        // High score
        if finalScore >= 100 {
            report(.score100)
        }
        if finalScore >= 200 {
            report(.score200)
        }
        if finalScore >= 300 {
            report(.score300)
        }
        if finalScore >= 400 {
            report(.score400)
        }
        if finalScore >= 500 {
            report(.score500)
        }
        
        // Accuracy
        if accuracy >= 0.8 {
            report(.accuracy80)
        }
        if accuracy >= 0.9 {
            report(.accuracy90)
        }
        if accuracy == 1.0 {
            report(.accuracy100)
        }
        
        // Play time (in seconds)
        if totaleTime >= 3600 {
            report(.playTime1Hour)
        }
        if totaleTime >= 5 * 3600 {
            report(.playTime5Hours)
        }
        if totaleTime >= 10 * 3600 {
            report(.playTime10Hours)
        }
    }
    
    private func report(_ achievment: GameCenterAchievment) {
        GameCenterService.shared.reportAchievement(achievment: achievment, percentComplete: 100)
    }
}
