//
//  ScoreService.swift
//  Roll Strike
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
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)        
        analyticsService.updateAnalytics(correctShots: gameCorrectShots,
                                         missedShots: gameMissedShots,
                                         didWin: isAWinner,
                                         finalScore: finalScore.total)
        gameCenterService?.reportScore(finalScore.total)
        let analyticsValue = analyticsService.analyticsPublisher.value
        achievementService?.updateAchievements(
            totalWins: analyticsValue.lifetimeWinnings,
            currentStreak: analyticsValue.currentWinningStreak,
            finalScore: finalScore.total
        )
        cancellables.removeAll()
        completion(finalScore)
    }
}

