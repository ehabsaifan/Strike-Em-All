//
//  Score.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/9/25.
//

import Foundation

struct Score: Equatable, Codable {
    let lastShotPointsEarned: Int
    let total: Int
    let winnerBonus: Int
    let timeStamp: Date
    
    init(lastShotPointsEarned: Int = 0,
         total: Int = 0,
         winnerBonus: Int = 0,
         timeStamp: Date = Date()) {
        self.lastShotPointsEarned = lastShotPointsEarned
        self.total = total
        self.winnerBonus = winnerBonus
        self.timeStamp = timeStamp
    }
}
