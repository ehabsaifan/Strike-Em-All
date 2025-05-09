//
//  Score.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/9/25.
//

import Foundation

struct Score: Equatable, Codable {
    let currentShotEarnedpoints: Int
    let winnerBonus: Int
    let timeBonus: Int
    let previousTotal: Int
    let comboMultiplier: Int
    let timeStamp: Date
    
    var total: Int {
        previousTotal + currentShotEarnedpoints + winnerBonus + timeBonus
    }
    
    init(currentShotEarnedpoints: Int = 0,
         winnerBonus: Int = 0,
         timeBonus: Int = 0,
         previousTotal: Int = 0,
         comboMultiplier: Int = 1,
         timeStamp: Date = Date()) {
        self.currentShotEarnedpoints = currentShotEarnedpoints
        self.winnerBonus = winnerBonus
        self.timeBonus = timeBonus
        self.previousTotal = previousTotal
        self.comboMultiplier = comboMultiplier
        self.timeStamp = timeStamp
    }
}
