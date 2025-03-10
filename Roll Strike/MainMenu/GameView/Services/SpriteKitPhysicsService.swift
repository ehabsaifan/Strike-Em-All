//
//  SpriteKitPhysicsService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/9/25.
//

import Foundation

class SpriteKitPhysicsService: PhysicsServiceProtocol {
    private weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void) {
            scene?.onBallStopped = completion
            scene?.rollBallToRandomPosition(maxY: maxY)
        }
    
    func moveBall(to position: CGPoint) {
        scene?.rollBall(to: position)
    }
    
    func resetBall() {
        scene?.resetBall()
    }
}
