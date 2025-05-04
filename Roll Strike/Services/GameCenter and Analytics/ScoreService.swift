//
//  ScoreService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation
import Combine

protocol ScoreServiceProtocol {
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    
    func gameStarted(player: Player)
    func recordScore(atRow row: Int, player: Player)
    func missedShot(player: Player)
    func gameEnded(player: Player, isAWinner: Bool, completion: @escaping (Score) -> Void)
}

class ScoreService: ScoreServiceProtocol, ObservableObject {
    let scorePublisher: CurrentValueSubject<Score, Never>
    
    private var scoreCalculator: ScoreCalculatorProtocol
    private var gameMissedShots = 0
    private var gameCorrectShots = 0
    private var startTime: Date?
    
    private var analyticsService: AnalyticsServiceProtocol
    private var gameCenterService: GameCenterProtocol?
    private var achievementService: AchievementServiceProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    init(calculator: ScoreCalculatorProtocol = ScoreCalculator(),
         analyticsService: AnalyticsServiceProtocol,
         gameCenterService: GameCenterProtocol?,
         achievementService: AchievementServiceProtocol?) {
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
        self.analyticsService = analyticsService
        self.gameCenterService = gameCenterService
        self.achievementService = achievementService
    }
    
    func gameStarted(player: Player) {
        scoreCalculator.startGame()
        startTime = Date()
    }
    
    func recordScore(atRow row: Int, player: Player) {
        gameCorrectShots += 1
        scoreCalculator.recordScore(atRow: row)
    }
    
    func missedShot(player: Player) {
        gameMissedShots += 1
        scoreCalculator.missedShot()
    }
    
    func gameEnded(player: Player, isAWinner: Bool, completion: @escaping (Score) -> Void) {
        guard let startTime else {
            return
        }
        let gameTimePlayed = Date().timeIntervalSince(startTime)
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)
        analyticsService.updateAnalytics(correctShots: gameCorrectShots,
                                         missedShots: gameMissedShots,
                                         didWin: isAWinner,
                                         finalScore: finalScore.total,
                                         gameTimePlayed: gameTimePlayed)
        
        let analyticsValue = analyticsService.analyticsPublisher.value
        let totalGames = analyticsValue.lifetimeGamesPlayed
        let totalWins = analyticsValue.lifetimeWinnings
        let winningStreak = analyticsValue.currentWinningStreak
        let playTotalTime   = analyticsValue.lifetimeTotalTimePlayed
        let perfectGames = analyticsValue.lifetimePerfectGamesCount
        let perfectStreak = analyticsValue.lifetimeLongestPerfectGamesStreak
        let accuracy = Double(analyticsValue.lifetimeCorrectShots) /
        Double(analyticsValue.lifetimeCorrectShots + analyticsValue.lifetimeMissedShots)
        
        gameCenterService?.report(finalScore.total, board: .score)
        gameCenterService?.report(totalWins, board: .totalWins)
        gameCenterService?.report(winningStreak, board: .longestStreak)
        gameCenterService?.report(totalGames, board: .gamesPlayed)
        
        achievementService?.updateAchievements(
            totalWins: totalWins,
            currentStreak: winningStreak,
            finalScore: finalScore.total,
            totalGames: totalGames,
            totaleTime: playTotalTime,
            perfectGames: perfectGames,
            perfectStreak: perfectStreak,
            accuracy: accuracy
            )
        cancellables.removeAll()
        completion(finalScore)
    }
}

