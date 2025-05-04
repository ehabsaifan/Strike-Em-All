//
//  ScoreCalculator.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/8/25.
//

import Foundation
import Combine

protocol ScoreCalculatorProtocol {
    var baseScore: Int { get }
    var comboMultiplier: Double { get }
    var timeBonusMultiplier: Double { get }
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    
    func startGame()
    func recordScore(atRow row: Int)
    func missedShot()
    func finishGame(isWinner: Bool) -> Score
}

class ScoreCalculator: ScoreCalculatorProtocol, ObservableObject {
    let baseScore: Int = 10
    let winnerBonus = 25
    private(set) var comboMultiplier: Double = 1.0
    private(set) var timeBonusMultiplier: Double = 1.0
    
    // Use a CurrentValueSubject so that changes propagate.
    var scorePublisher = CurrentValueSubject<Score, Never>(Score())
    
    private var streakRows: Set<Int> = []
    private var streakCompleteRows: Set<Int> = []
    private var gameStartTime: Date?
    
    private func reset() {
        scorePublisher.send(Score())
        comboMultiplier = 1.0
        timeBonusMultiplier = 1.0
        streakRows = []
        streakCompleteRows = []
        gameStartTime = nil
    }
    
    func startGame() {
        reset()
        gameStartTime = Date()
    }
    
    func recordScore(atRow row: Int) {
        var shotMultiplier = 1.0
        if streakRows.contains(row) {
            shotMultiplier = 1.2
            streakCompleteRows.insert(row)
        } else if comboMultiplier == 1 && !streakRows.isEmpty {
            streakRows.insert(row)
            shotMultiplier *= 1.1
        } else {
            streakRows.insert(row)
            shotMultiplier = 1.0
        }
        comboMultiplier *= shotMultiplier
        
        let pointsEarned = Int(Double(baseScore) * comboMultiplier)
        let previousScore = scorePublisher.value.total
        let newScore = Score(lastShotPointsEarned: pointsEarned, total: previousScore + pointsEarned, timeStamp: Date())
        scorePublisher.send(newScore)
        print("Score updated: \(newScore), combo: \(comboMultiplier)")
    }
    
    func missedShot() {
        streakRows = []
        streakCompleteRows = []
        comboMultiplier = 1.0
    }
    
    func finishGame(isWinner: Bool) -> Score {
        guard let start = gameStartTime else { return scorePublisher.value }
        let elapsedSeconds = Date().timeIntervalSince(start)
        if elapsedSeconds < 60 {
            timeBonusMultiplier = 1.1
        } else if elapsedSeconds < 120 {
            timeBonusMultiplier = 1.05
        } else {
            timeBonusMultiplier = 1.0
        }
        let winnerPoints = isWinner ? winnerBonus : 0
        let previousTotal = scorePublisher.value.total
        let bonus = Int(Double(previousTotal) * timeBonusMultiplier) - previousTotal
        let finalScore = Score(lastShotPointsEarned: bonus,
                               total: previousTotal + bonus + winnerPoints,
                               winnerBonus: winnerPoints,
                               timeStamp: Date())
        scorePublisher.send(finalScore)
        print("Game ended: final score: \(finalScore.total) with bonus multiplier \(timeBonusMultiplier)")
        return finalScore
    }
}
