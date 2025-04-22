//
//  AchievementService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/12/25.
//

import Foundation

protocol AchievementServiceProtocol {
    /// Call this when the game ends to check and report any earned achievements.
    func updateAchievements(totalWins: Int,
                            currentStreak: Int,
                            finalScore: Int)
}

class AchievementService: ObservableObject, AchievementServiceProtocol {
    static let shared = AchievementService()
    private init() {}
    
    func updateAchievements(totalWins: Int, currentStreak: Int, finalScore: Int) {
        print("Reporting achievements. totalWins: \(totalWins) | currentStreak: \(currentStreak) | finalScore: \(finalScore)")
        if currentStreak >= 5 {
            GameCenterService.shared.reportAchievement(achievment: .fiveWinsStreak, percentComplete: 100)
        }
        if currentStreak >= 10 {
            GameCenterService.shared.reportAchievement(achievment: .tenWinsStreak, percentComplete: 100)
        }
        if currentStreak >= 5 {
            GameCenterService.shared.reportAchievement(achievment: .fiveWins, percentComplete: 100)
        }
        if currentStreak >= 25 {
            GameCenterService.shared.reportAchievement(achievment: .twintyFiveWins, percentComplete: 100)
        }
        // You can add more achievement conditions based on score thresholds, accuracy, or time played.
    }
}
