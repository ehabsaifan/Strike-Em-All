//
//  ScoreManager.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation
import Combine

protocol ScoreManagerProtocol {
    var currentScore: AnyPublisher<Int, Never> { get }
       
    func gameStarted(player: String)
    func recordScore(atRow row: Int, player: String)
    func missedShot(player: String)
    func gameEnded(player: String, isAWinner: Bool)
}

class ScoreManager: ScoreManagerProtocol, ObservableObject {
    // MARK: - Publisher Setup
    @Published private var _currentScore: Int = 0
    var currentScore: AnyPublisher<Int, Never> {
        $_currentScore.eraseToAnyPublisher()
    }
    
    static let shared = ScoreManager()
    
    // MARK: - Game State Management
    private var scoreTracker: CurrentGameScoreServiceProtocol
    private var winningCount = 0
    private var winningStreak = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.scoreTracker = CurrentGameScoreTrackingService()
    }

    func gameStarted(player: String) {
        _currentScore = 0
        scoreTracker.startGame()
        
        // Proper Combine pipeline setup
        scoreTracker.currentScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newScore in
                print("New score: \(newScore)")
                self?._currentScore = newScore
            }
            .store(in: &cancellables)
    }

    func recordScore(atRow row: Int, player: String) {
        scoreTracker.recordScore(atRow: row)
    }
    
    func missedShot(player: String) {
        scoreTracker.missedShot()
    }
    
    func gameEnded(player: String, isAWinner: Bool) {
        scoreTracker.gameEnded { [weak self] finalScore in
            guard let self = self else { return }
            print("Final Score: \(finalScore)")
            if isAWinner {
                self.winningCount += 1
                self.winningStreak += 1
                print("\(player) won with score: \(finalScore)")
            } else {
                self.winningStreak = 0
                print("\(player) lost with score: \(finalScore)")
            }
            
            GameCenterManager.shared.reportScore(finalScore)
            self.reportAchievement()
            self.cancellables.removeAll()
        }
    }
    
    private func reportAchievement() {
        // Implementation for achievement reporting
        switch winningStreak {
        case 5:
            GameCenterManager.shared.reportAchievement(achievment: .fiveWinsStreak,
                                                       percentComplete: 100)
        case 10:
            GameCenterManager.shared.reportAchievement(achievment: .tenWinsStreak,
                                                       percentComplete: 100)
        default:
            break
        }
        
        switch winningCount {
        case 5:
            GameCenterManager.shared.reportAchievement(achievment: .fiveWins,
                                                       percentComplete: 100)
        case 25:
            GameCenterManager.shared.reportAchievement(achievment: .twintyFiveWins,
                                                       percentComplete: 100)
        default:
            break
        }
    }
}
