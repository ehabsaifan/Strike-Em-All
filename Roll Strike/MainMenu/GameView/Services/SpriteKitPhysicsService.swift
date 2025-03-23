//
//  SpriteKitPhysicsService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/9/25.
//

import SpriteKit
import UIKit

protocol PhysicsServiceProtocol {
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void)
    func moveBall(with impulse: CGVector, ball: RollingObject, completion: @escaping (CGPoint) -> Void)
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
    
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void) {
        scene?.onBallStopped = completion
        scene?.rollBallToRandomPosition(maxY: maxY)
    }
    
    func moveBall(with impulse: CGVector, ball: RollingObject, completion: @escaping (CGPoint) -> Void) {
        guard let scene = scene else { return }
        
        let adjustedImpulse = getAdjustedVector(rollingObject: ball, with: impulse)
        let action = getMovementAction(rollingObject: ball, with: impulse)
        
        if let action {
            scene.runMovementAction(action)
        } else {
            scene.applyImpulse(adjustedImpulse, on: ball)
        }
        scene.onBallStopped = completion
    }
    
    func resetBall() {
        scene?.resetBall()
    }
}

//MARK: - Physics Changes
extension SpriteKitPhysicsService {
    private func getAdjustedVector(rollingObject: RollingObject, with impulse: CGVector) -> CGVector {
        switch rollingObject.type {
        case .ball,
                .ironBall:
            return impulse
        case .crumpledPaper:
            let randomOffset = CGFloat.random(in: -4...4)
            return CGVector(dx: (impulse.dx + randomOffset) * 1.5, dy: (impulse.dy + randomOffset) * 1.5)
        }
    }
    
    private func getMovementAction(rollingObject: RollingObject, with impulse: CGVector) -> SKAction? {
        switch rollingObject.type {
        case .ball,
                .ironBall:
            return nil
            
        case .crumpledPaper:
            let object = rollingObject as! CrumpledPaper
            let target = CGPoint(x: start.x + impulse.dx, y: start.y + impulse.dy)
            let path = CGMutablePath()
            path.move(to: start)
            let midX = (start.x + target.x) / 2
            let midY = (start.y + target.y) / 2
            let controlOffset: CGFloat = 30
            let controlPoint1 = CGPoint(x: midX - controlOffset, y: midY + controlOffset)
            let controlPoint2 = CGPoint(x: midX + controlOffset, y: midY - controlOffset)
            path.addCurve(to: target, control1: controlPoint1, control2: controlPoint2)
            let distance = hypot(target.x - start.x, target.y - start.y)
            let duration = 1.0/TimeInterval(distance / (object.speed * 100))
            let action = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
            action.timingMode = .easeInEaseOut
            return action
        }
    }
}
