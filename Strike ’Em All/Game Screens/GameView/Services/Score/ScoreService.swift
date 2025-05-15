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
    
    func gameStarted(player: Player)
    func recordScore(atRow row: Int, player: Player)
    func missedShot(player: Player)
    func gameEnded(player: Player, isAWinner: Bool, completion: @escaping (Score) -> Void)
}

class ScoreService: ScoreServiceProtocol, ObservableObject {
    let scorePublisher: CurrentValueSubject<Score, Never>
    private(set) var gameTimePlayed: TimeInterval? = nil
    
    private var scoreCalculator: ScoreCalculatorProtocol
    private var gameMissedShots = 0
    private var gameCorrectShots = 0
    private var startTime: Date?
    
    private(set) var analyticsService: AnalyticsServiceProtocol
    private var gcReportService: GameCenterReportServiceProtocol?
    
    init(calculator: ScoreCalculatorProtocol = ScoreCalculator(),
         analyticsService: AnalyticsServiceProtocol,
         gcReportService: GameCenterReportServiceProtocol?) {
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
        self.analyticsService = analyticsService
        self.gcReportService = gcReportService
    }
    
    func gameStarted(player: Player) {
        scoreCalculator.startGame()
        startTime = Date()
        gameTimePlayed = nil
        gameMissedShots = 0
        gameCorrectShots = 0
    }
    
    func recordScore(atRow row: Int, player: Player) {
        gameCorrectShots += 1
        print("Correct shot now \(gameCorrectShots)")
        scoreCalculator.recordScore(atRow: row)
    }
    
    func missedShot(player: Player) {
        gameMissedShots += 1
        print("Missed shot now \(gameMissedShots)")
        scoreCalculator.missedShot()
    }
    
    func gameEnded(player: Player, isAWinner: Bool, completion: @escaping (Score) -> Void) {
        guard let startTime else {
            return
        }
        gameTimePlayed = Date().timeIntervalSince(startTime)
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)
        analyticsService.updateAnalytics(correctShots: gameCorrectShots,
                                         missedShots: gameMissedShots,
                                         didWin: isAWinner,
                                         finalScore: finalScore.total,
                                         gameTimePlayed: gameTimePlayed!)
        
        gcReportService?.gameEnded(score: finalScore, analytics: analyticsService.analyticsPublisher.value)
        print(finalScore)
        completion(finalScore)
    }
}

