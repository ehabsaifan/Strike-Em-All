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
    
    func gameStarted(player: String)
    func recordScore(atRow row: Int, player: String)
    func missedShot(player: String)
    func gameEnded(player: String, isAWinner: Bool, completion: @escaping (Score) -> Void)
}

class ScoreService: ScoreServiceProtocol, ObservableObject {
    let scorePublisher: CurrentValueSubject<Score, Never>
    private var scoreCalculator: ScoreCalculatorProtocol
    private var gameMissedShots = 0
    private var gameCorrectShots = 0
    private var analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(calculator: ScoreCalculatorProtocol = ScoreCalculator(),
         analyticsService: AnalyticsServiceProtocol) {
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
        self.analyticsService = analyticsService
    }
    
    func gameStarted(player: String) {
        scoreCalculator.startGame()
    }
    
    func recordScore(atRow row: Int, player: String) {
        gameCorrectShots += 1
        scoreCalculator.recordScore(atRow: row)
    }
    
    func missedShot(player: String) {
        gameMissedShots += 1
        scoreCalculator.missedShot()
    }
    
    func gameEnded(player: String, isAWinner: Bool, completion: @escaping (Score) -> Void) {
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)

        GameCenterService.shared.reportScore(finalScore.total)
        analyticsService.updateAnalytics(correctShots: gameCorrectShots,
                                                missedShots: gameMissedShots,
                                                didWin: isAWinner,
                                                finalScore: finalScore.total)
        cancellables.removeAll()
        completion(finalScore)
    }
}

