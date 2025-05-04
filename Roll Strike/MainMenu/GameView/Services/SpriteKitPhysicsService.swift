//
//  SpriteKitPhysicsService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/9/25.
//

import SpriteKit
import UIKit

protocol PhysicsServiceProtocol {
    func updateBallPosition(with offset: CGSize)
    func moveBall(with impulse: CGVector, ball: RollingObject, completion: @escaping (CGPoint) -> Void)
    func setRollingObject(_ object: RollingObject)
    func setWrapAroundEnabled(_ enabled: Bool)
    func resetBall()
}

class SpriteKitPhysicsService: PhysicsServiceProtocol {
    private weak var scene: GameScene?
    
    private var start: CGPoint {
        scene?.ballStartPosition ?? CGPoint.zero
    }
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func updateBallPosition(with offset: CGSize) {
        scene?.updateBallPosition(with: offset)
    }

    func moveBall(with impulse: CGVector, ball: RollingObject, completion: @escaping (CGPoint) -> Void) {
        guard let scene = scene else { return }
        scene.applyImpulse(impulse, on: ball)
        scene.onBallStopped = completion
    }
    
    func setRollingObject(_ object: RollingObject) {
        scene?.ballType = object.type
    }
    
    func setWrapAroundEnabled(_ enabled: Bool) {
        scene?.wrapAroundEnabled = enabled
    }
    
    func resetBall() {
        scene?.resetBall()
    }
}
