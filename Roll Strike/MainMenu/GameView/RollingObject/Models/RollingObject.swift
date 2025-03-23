//
//  RollingObject.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

protocol RollingObject {
    var type: RollingObjectType { get }
    var name: String { get }
    var speed: Double { get }
    func roll(maxRows: Int) -> Int
    func adjustImpulse(_ impulse: CGVector) -> CGVector
}

class Ball: RollingObject {
    var name = "Ball"
    var speed = 1.0
    let type = RollingObjectType.ball
    
    func roll(maxRows: Int) -> Int {
        // For now, we simulate a roll with a random landing row.
        return Int.random(in: 0..<maxRows)
    }
    
    func adjustImpulse(_ impulse: CGVector) -> CGVector {
            // Regular ball: no change.
            return impulse
        }
}

class FireBall: RollingObject {
    var name = "FireBall"
    var speed = 1.5
    let type = RollingObjectType.fireBall
    
    func roll(maxRows: Int) -> Int {
        return Int.random(in: 0..<maxRows)
    }
    
    func adjustImpulse(_ impulse: CGVector) -> CGVector {
            return CGVector(dx: impulse.dx * 1.2, dy: impulse.dy * 1.2)
        }
}

class CrumpledPaper: RollingObject {
    var name = "Crumpled Paper"
    var speed = 2.0
    let type = RollingObjectType.crumpledPaper
    
    func roll(maxRows: Int) -> Int {
        return Int.random(in: 0..<maxRows)
    }
    
    func adjustImpulse(_ impulse: CGVector) -> CGVector {
            let randomOffset = CGFloat.random(in: -2...2)
            return CGVector(
                dx: (impulse.dx + randomOffset) * 1.1,
                dy: (impulse.dy + randomOffset) * 1.1
            )
        }
}

class IronBall: RollingObject {
    var name = "Iron Ball"
    var speed = 0.8
    let type = RollingObjectType.ironBall
    
    func roll(maxRows: Int) -> Int {
        return Int.random(in: 0..<maxRows)
    }
    
    func adjustImpulse(_ impulse: CGVector) -> CGVector {
            return CGVector(dx: impulse.dx * 0.1, dy: impulse.dy * 0.1)
        }
}
