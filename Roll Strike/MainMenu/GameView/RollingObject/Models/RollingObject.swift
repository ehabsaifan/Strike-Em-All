//
//  RollingObject.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

protocol RollingObject {
    var name: String { get }
    var speed: Double { get }
    var behavior: RollingBehavior { get }
    func roll(maxRows: Int) -> Int
}

class Ball: RollingObject {
    var name = "Ball"
    var speed = 1.0
    var behavior = RollingBehavior.normal
    
    func roll(maxRows: Int) -> Int {
        // For now, we simulate a roll with a random landing row.
        return Int.random(in: 0..<maxRows)
    }
}

class FireBall: RollingObject {
    var name = "FireBall"
    var speed = 1.5
    var behavior = RollingBehavior.fast
    
    func roll(maxRows: Int) -> Int {
        return Int.random(in: 0..<maxRows)
    }
}

class CrumpledPaper: RollingObject {
    var name = "Crumpled Paper"
    var speed = 0.8
    var behavior = RollingBehavior.unpredictable
    
    func roll(maxRows: Int) -> Int {
        return Int.random(in: 0..<maxRows)
    }
}
