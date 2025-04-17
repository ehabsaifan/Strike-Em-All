//
//  AchievementService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/12/25.
//

import Foundation

class AchievementService: ObservableObject {
    static let shared = AchievementService()
    private init() {}
    
    func updateAchievements(winningCount: Int, winningStreak: Int, score: Int) {
        // Example achievement logic:
        if winningStreak >= 5 {
            GameCenterService.shared.reportAchievement(achievment: .fiveWinsStreak, percentComplete: 100)
        }
        if winningStreak >= 10 {
            GameCenterService.shared.reportAchievement(achievment: .tenWinsStreak, percentComplete: 100)
        }
        if winningCount >= 5 {
            GameCenterService.shared.reportAchievement(achievment: .fiveWins, percentComplete: 100)
        }
        if winningCount >= 25 {
            GameCenterService.shared.reportAchievement(achievment: .twintyFiveWins, percentComplete: 100)
        }
        // You can add more achievement conditions based on score thresholds, accuracy, or time played.
    }
}
