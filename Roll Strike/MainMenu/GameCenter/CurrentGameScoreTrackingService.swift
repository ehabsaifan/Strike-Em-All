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
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    
    func startGame()
    func recordScore(atRow row: Int)
    func missedShot()
    func gameEnded(completion: (Score) -> Void)
}

class CurrentGameScoreTrackingService: CurrentGameScoreServiceProtocol, ObservableObject {
    var scorePublisher = CurrentValueSubject<Score, Never>(Score())
    
    let baseScore: Int = 10
    private(set) var comboMultiplier: Double = 1.0
    private(set) var timeBonusMultiplier: Double = 1.0
    
    // These values may be tuned:
    private var streakRows: Set<Int> = []
    private var streakCompleteRows: Set<Int> = []
    
    // For time-based bonus
    private var gameStartTime: Date?
    
    private func reset() {
        scorePublisher.send(Score())
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
        var shotMultiplier = 1.0
        print("shotMultiplier = comboMultiplier: \(shotMultiplier)")
        if streakRows.contains(row) {
            shotMultiplier = 1.2
            streakCompleteRows.insert(row)
        } else {
            streakRows.insert(row)
            shotMultiplier = comboMultiplier == 1 ? 1 : 1.1
        }
        comboMultiplier *= shotMultiplier
        
        let pointsEarned = Int(Double(baseScore) * comboMultiplier)
        let previousTotal = scorePublisher.value.total
        scorePublisher.send(Score(lastShotPointsEarned: pointsEarned,
                                  total: pointsEarned + previousTotal,
                                  timeStamp: Date()))
        print("Score: \(scorePublisher.value), comboMultiplier: \(comboMultiplier)")
    }
    
    func missedShot() {
        print("missedShot")
        streakRows = []
        streakCompleteRows = []
        comboMultiplier = 1.0
    }
    
    func gameEnded(completion: (Score) -> Void) {
        guard let gameStartTime = gameStartTime else { return }
        
        let elapsedSeconds = Date().timeIntervalSince(gameStartTime)
        if elapsedSeconds < 60 {
            timeBonusMultiplier = 1.1
        } else if elapsedSeconds < 120 {
            timeBonusMultiplier = 1.05
        } else {
            timeBonusMultiplier = 1.0
        }
        
        let previousTotal = scorePublisher.value.total
        let final = Int(Double(previousTotal) * timeBonusMultiplier)
        scorePublisher.send(Score(lastShotPointsEarned: final - previousTotal,
                                  total: final,
                                  timeStamp: Date()))
        completion(scorePublisher.value)
    }
}
