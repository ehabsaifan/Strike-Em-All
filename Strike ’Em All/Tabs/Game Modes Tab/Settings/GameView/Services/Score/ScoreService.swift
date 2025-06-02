//
//  ScoreService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation
import Combine

protocol ScoreServiceProtocol {
    var gameTimePlayed: TimeInterval? { get }
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    var analyticsService: AnalyticsServiceProtocol { get }
    
    func gameStarted()
    func recordScore(atRow row: Int)
    func missedShot()
    func updateScore(dict: [Int: Int], player: Player)
    func gameEnded(isAWinner: Bool, completion: @escaping (Score) -> Void)
}

class ScoreService: ScoreServiceProtocol, ObservableObject {
    let scorePublisher: CurrentValueSubject<Score, Never>
    private(set) var gameTimePlayed: TimeInterval? = nil
    
    private var scoreCalculator: ScoreCalculatorProtocol
    private var gameMissedShots = 0
    private var gameCorrectShots = 0
    private var startTime: Date?
    private var totalShotsCount = 0
    
    private(set) var analyticsService: AnalyticsServiceProtocol
    private var gcReportService: GameCenterReportServiceProtocol?
    
    private let player: Player
    
    init(player: Player,
         calculator: ScoreCalculatorProtocol = ClassicScoreCalculator(),
         analyticsService: AnalyticsServiceProtocol,
         gcReportService: GameCenterReportServiceProtocol?) {
        self.player = player
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
        self.analyticsService = analyticsService
        self.gcReportService = gcReportService
    }
    
    func gameStarted() {
        scoreCalculator.startGame()
        startTime = Date()
        gameTimePlayed = nil
        gameMissedShots = 0
        gameCorrectShots = 0
        totalShotsCount = 0
    }
    
    func updateScore(dict: [Int: Int], player: Player) {
        if self.player == player {
            totalShotsCount += 1
        }
        gameCorrectShots = 0
        for val in dict.values {
            gameCorrectShots += max(0, min(val, 2))
        }
        scoreCalculator.updateScpore(scoreDict: dict)
    }
    
    func recordScore(atRow row: Int) {
        guard self.player == player else {
            return
        }
        totalShotsCount += 1
        gameCorrectShots += 1
        scoreCalculator.recordScore(atRow: row)
    }
    
    func missedShot() {
        guard self.player == player else {
            return
        }
        totalShotsCount += 1
        gameMissedShots += 1
        scoreCalculator.missedShot()
    }
    
    func gameEnded(isAWinner: Bool, completion: @escaping (Score) -> Void) {
        guard let startTime else {
            return
        }
        gameTimePlayed = Date().timeIntervalSince(startTime)
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)
        analyticsService.updateAnalytics(correctShots: gameCorrectShots,
                                         missedShots: totalShotsCount - gameCorrectShots,
                                         didWin: isAWinner,
                                         finalScore: finalScore.total,
                                         gameTimePlayed: gameTimePlayed!)
        
        gcReportService?.gameEnded(score: finalScore, analytics: analyticsService.analyticsPublisher.value)
        completion(finalScore)
    }
}

