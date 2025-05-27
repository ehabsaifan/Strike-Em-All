//
//  ScoreCalculator.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/8/25.
//

import Foundation
import Combine

protocol ScoreCalculatorProtocol {
    var startTime: Date? { get }
    var baseScore: Int { get }
    var comboMultiplier: Int { get }
    var scorePublisher: CurrentValueSubject<Score, Never> { get }
    
    func startGame()
    func recordScore(atRow row: Int)
    func missedShot()
    func finishGame(isWinner: Bool) -> Score
}

class ScoreCalculator: ScoreCalculatorProtocol, ObservableObject {
    let baseScore: Int = 1
    let winnerBonus = 25
    private(set) var comboMultiplier: Int = 1
    
    // Use a CurrentValueSubject so that changes propagate.
    var scorePublisher = CurrentValueSubject<Score, Never>(Score())
    
    private var streakRows: Set<Int> = []
    private var streakCompleteRows: Set<Int> = []
    private(set) var startTime: Date?
    
    private func reset() {
        scorePublisher.send(Score())
        comboMultiplier = 1
        streakRows = []
        streakCompleteRows = []
        startTime = nil
    }
    
    func startGame() {
        reset()
        startTime = Date()
    }
    
    func recordScore(atRow row: Int) {
        var shotMultiplier = 2
        if streakRows.contains(row) {
            shotMultiplier = 4
            streakCompleteRows.insert(row)
        } else if comboMultiplier == 1 && !streakRows.isEmpty {
            streakRows.insert(row)
            shotMultiplier = 3
        } else {
            streakRows.insert(row)
            shotMultiplier = 2
        }
        comboMultiplier += shotMultiplier
        
        let pointsEarned = baseScore * comboMultiplier
        let previousScore = scorePublisher.value.total
        let newScore = Score(currentShotEarnedpoints: pointsEarned,
                             previousTotal: previousScore,
                             comboMultiplier: comboMultiplier,
                             timeStamp: Date())
        scorePublisher.send(newScore)
    }
    
    func missedShot() {
        streakRows = []
        streakCompleteRows = []
        comboMultiplier = 1
        let previousTotal = scorePublisher.value.total
        scorePublisher.send(Score(currentShotEarnedpoints: 0,
                                  winnerBonus: 0,
                                  timeBonus: 0,
                                  previousTotal: previousTotal,
                                  comboMultiplier: 1,
                                  timeStamp: Date()))
    }
    
    func finishGame(isWinner: Bool) -> Score {
        guard let start = startTime else { return scorePublisher.value }
        let elapsedSeconds = Date().timeIntervalSince(start)
        let timeBonus: Int
        if elapsedSeconds < 60 {
            timeBonus = 10
        } else if elapsedSeconds < 120 {
            timeBonus = 5
        } else {
            timeBonus = 0
        }
        let winnerPoints = isWinner ? winnerBonus : 0
        let previousTotal = scorePublisher.value.total
        let finalScore = Score(currentShotEarnedpoints: 0,
                               winnerBonus: winnerPoints,
                               timeBonus: timeBonus,
                               previousTotal: previousTotal,
                               timeStamp: Date())
        scorePublisher.send(finalScore)
        return finalScore
    }
}

class TimedScoreCalculator: ScoreCalculator {
    private let totalTime: TimeInterval
    
    init(totalTime: TimeInterval) {
        self.totalTime = totalTime
        super.init()
    }
    
    override func finishGame(isWinner: Bool) -> Score {
        guard let start = startTime else { return  scorePublisher.value }
        let previousTotal = scorePublisher.value.total
        let elapsed = Date().timeIntervalSince(start)
        let timeBonusPercentage = isWinner ? max(0, (totalTime - elapsed) / totalTime) : 0
        let timeBonus = Int(Double(previousTotal) + timeBonusPercentage * 0.1)
        let winnerPoints = isWinner ? winnerBonus : 0
        let final = Score(currentShotEarnedpoints: 0,
                          winnerBonus: winnerPoints,
                          timeBonus: timeBonus,
                          previousTotal: previousTotal,
                          timeStamp: Date())
        scorePublisher.send(final)
        return final
    }
}
