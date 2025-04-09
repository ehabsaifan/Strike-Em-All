//
//  Score.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/9/25.
//

import Foundation

struct Score {
    let lastShotPointsEarned: Int
    let total: Int
    let timeStamp: Date?
    
    init(lastShotPointsEarned: Int = 0, total: Int = 0, timeStamp: Date? = nil) {
        self.lastShotPointsEarned = lastShotPointsEarned
        self.total = total
        self.timeStamp = timeStamp
    }
}
