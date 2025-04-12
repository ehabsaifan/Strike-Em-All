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
    private var winningCount = 0
    private var winningStreak = 0
    private var cancellables = Set<AnyCancellable>()
    
    init(calculator: ScoreCalculatorProtocol = ScoreCalculator()) {
        self.scoreCalculator = calculator
        self.scorePublisher = calculator.scorePublisher
    }
    
    func gameStarted(player: String) {
        scoreCalculator.startGame()
    }
    
    func recordScore(atRow row: Int, player: String) {
        scoreCalculator.recordScore(atRow: row)
    }
    
    func missedShot(player: String) {
        scoreCalculator.missedShot()
    }
    
    func gameEnded(player: String, isAWinner: Bool, completion: @escaping (Score) -> Void) {
        let finalScore = scoreCalculator.finishGame(isWinner: isAWinner)
        if isAWinner {
            winningCount += 1
            winningStreak += 1
        } else {
            winningStreak = 0
        }
        // Report the score and update achievements via the AchievementManager (see next section).
        GameCenterManager.shared.reportScore(finalScore.total)
        AchievementManager.shared.updateAchievements(winningCount: winningCount, winningStreak: winningStreak, score: finalScore.total)
        cancellables.removeAll()
        completion(finalScore)
    }
}

