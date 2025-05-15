//
//  GameCenterReportService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/12/25.
//

import Foundation

protocol GameCenterReportServiceProtocol {
    func gameEnded(score: Score, analytics: GameAnalytics)
}

class GameCenterReportService: ObservableObject, GameCenterReportServiceProtocol {
    let gcService: GameCenterProtocol
    
    init(gcService: GameCenterProtocol) {
        self.gcService = gcService
    }
    
    func gameEnded(score: Score, analytics: GameAnalytics) {
        let totalGames = analytics.lifetimeGamesPlayed
        let totalWins = analytics.lifetimeWinnings
        let winningStreak = analytics.currentWinningStreak
        
        gcService.report(score.total, board: .score)
        gcService.report(totalWins, board: .totalWins)
        gcService.report(winningStreak, board: .longestStreak)
        gcService.report(totalGames, board: .gamesPlayed)
        
        let achievements = GameCenterAchievment.getAchievementsObtained(for: score.total, analytics: analytics)
        gcService.reportAchievements(achievements)
    }
}
