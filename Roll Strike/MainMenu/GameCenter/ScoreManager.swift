//
//  ScoreManager.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation
import Combine

protocol ScoreManagerProtocol {
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    
    func gameStarted(player: String)
    func recordScore(atRow row: Int, player: String)
    func missedShot(player: String)
    func gameEnded(player: String, isAWinner: Bool, completion: @escaping (Score) -> Void)
}

class ScoreManager: ScoreManagerProtocol, ObservableObject {
    let scorePublisher: CurrentValueSubject<Score, Never>
    private var scoreCalculator: ScoreCalculatorProtocol
    private var gameMissedShots = 0
    private var gameCorrectShots = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(calculator: ScoreCalculatorProtocol = ScoreCalculator()) {
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
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
        if isAWinner {
            lifeTimeLongesttWinningStreak += 1
        } else {
            lifeTimeLongesttWinningStreak = 0
        }

        GameCenterManager.shared.reportScore(finalScore.total)
        AnalyticsManager.shared.updateAnalytics(correctShots: correctShots,
                                                missedShots: missedShots,
                                                didWin: player)
        cancellables.removeAll()
        completion(finalScore)
    }
}

