//
//  SpriteKitPhysicsService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/9/25.
//

import Foundation

protocol PhysicsServiceProtocol {
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void)
    func moveBall(with impulse: CGVector, completion: @escaping (CGPoint) -> Void)
    func resetBall()
}

class SpriteKitPhysicsService: PhysicsServiceProtocol {
    private weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void) {
        print("@@ PhysicsService rollBallWithRandomPosition")
        scene?.onBallStopped = completion
        scene?.rollBallToRandomPosition(maxY: maxY)
    }
    
    func moveBall(with impulse: CGVector, completion: @escaping (CGPoint) -> Void) {
        print("@@ PhysicsService moveBall")
        scene?.onBallStopped = completion
        scene?.applyImpulse(impulse)
    }
    
    func resetBall() {
        print("@@ PhysicsService resetBall")
        scene?.resetBall()
    }
}
