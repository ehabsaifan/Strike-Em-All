//
//  CurrentGameScoreTrackingService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/8/25.
//

import Foundation
import Combine

protocol CurrentGameScoreServiceProtocol {
    var baseScore: Int { get }
    var comboMultiplier: Double { get }
    var timeBonusMultiplier: Double { get }
    var currentScore: AnyPublisher<Int, Never> { get }
    
    func startGame()
    func recordScore(atRow row: Int)
    func missedShot()
    func gameEnded(completion: @escaping (Int) -> Void)
}

class CurrentGameScoreTrackingService: CurrentGameScoreServiceProtocol, ObservableObject {
    let baseScore: Int = 10
    private(set) var comboMultiplier: Double = 1.0
    private(set) var timeBonusMultiplier: Double = 1.0
    
    // Private @Published property for internal state management
    @Published private var _currentScore: Int = 0
    
    // Public publisher exposing the score
    var currentScore: AnyPublisher<Int, Never> {
        $_currentScore
            .eraseToAnyPublisher()
    }
    
    // These values may be tuned:
    private var streakRows: Set<Int> = []
    private var streakCompleteRows: Set<Int> = []
    
    // For time-based bonus
    private var gameStartTime: Date?
    
    private func reset() {
        _currentScore = 0
        comboMultiplier = 1.0
        timeBonusMultiplier = 1.0
        streakRows = []
        streakCompleteRows = []
        gameStartTime = nil
    }
    
    // MARK: - Public API
    func startGame() {
        reset()
        gameStartTime = Date()
    }
    
    func recordScore(atRow row: Int) {
        var shotMultiplier = comboMultiplier
        print("shotMultiplier = comboMultiplier: \(shotMultiplier)")
        if streakRows.contains(row) {
            shotMultiplier *= 1.2
            streakCompleteRows.insert(row)
        } else {
            streakRows.insert(row)
            let factor = shotMultiplier == 1 ? 1 : 1.1
            shotMultiplier *= factor
        }
        comboMultiplier *= shotMultiplier
        
        let pointsEarned = Int(Double(baseScore) * comboMultiplier * timeBonusMultiplier)
        _currentScore += pointsEarned  // Modify underlying value

        print("shotMultiplier: \(shotMultiplier), comboMultiplier: \(comboMultiplier), score: \(_currentScore)")
    }
    
    func missedShot() {
        streakRows = []
        streakCompleteRows = []
        comboMultiplier = 1.0
    }
    
    func gameEnded(completion: @escaping (Int) -> Void) {
        guard let gameStartTime = gameStartTime else { return }
        
        let elapsedSeconds = Date().timeIntervalSince(gameStartTime)
        if elapsedSeconds < 60 {
            timeBonusMultiplier = 1.1
        } else if elapsedSeconds < 120 {
            timeBonusMultiplier = 1.05
        } else {
            timeBonusMultiplier = 1.0
        }
        
        let bonusPoints = Int(Double(_currentScore) * timeBonusMultiplier) - _currentScore
        _currentScore += bonusPoints
        print("Time bonus multiplier set to: \(timeBonusMultiplier) for elapsed time: \(elapsedSeconds), bonusPoints: \(bonusPoints), score: \(_currentScore)")
        
        // Call the completion with the new score.
        completion(_currentScore)
    }
}
