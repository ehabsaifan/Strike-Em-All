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
    static let shared = ScoreManager()
    
    private var scoreCalculator: ScoreCalculatorProtocol
    private var winningCount = 0
    private var winningStreak = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.scoreCalculator = ScoreCalculator()
        self.scorePublisher = (scoreCalculator as! ScoreCalculator).scorePublisher
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
        let finalScore = scoreCalculator.finishGame()
        if isAWinner {
            winningCount += 1
            winningStreak += 1
        } else {
            winningStreak = 0
        }
        GameCenterManager.shared.reportScore(finalScore.total)
        self.reportAchievement()
        cancellables.removeAll()
        completion(finalScore)
    }
    
    private func reportAchievement() {
        // Report achievements based on streaks.
        switch winningStreak {
        case 5:
            GameCenterManager.shared.reportAchievement(achievment: .fiveWinsStreak, percentComplete: 100)
        case 10:
            GameCenterManager.shared.reportAchievement(achievment: .tenWinsStreak, percentComplete: 100)
        default:
            break
        }
        switch winningCount {
        case 5:
            GameCenterManager.shared.reportAchievement(achievment: .fiveWins, percentComplete: 100)
        case 25:
            GameCenterManager.shared.reportAchievement(achievment: .twintyFiveWins, percentComplete: 100)
        default:
            break
        }
    }
}
