//
//  SpriteKitPhysicsService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/9/25.
//

import SpriteKit
import UIKit

protocol PhysicsServiceProtocol {
    func updateBallPosition(with offset: CGSize)
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
    
    func updateBallPosition(with offset: CGSize) {
        scene?.updateBallPosition(with: offset)
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
            return impulse //CGVector(dx: (impulse.dx + randomOffset) * 1.5, dy: (impulse.dy + randomOffset) * 1.5)
        }
    }
    
    private func getMovementAction(rollingObject: RollingObject, with impulse: CGVector) -> SKAction? {
        switch rollingObject.type {
        case .ball,
                .ironBall:
            return nil
            
        case .crumpledPaper:
            return nil
//            let object = rollingObject as! CrumpledPaper
//            let target = CGPoint(x: start.x + impulse.dx, y: start.y + impulse.dy)
//            
//            // Create a wavy zigzag path
//            let path = CGMutablePath()
//            path.move(to: start)
//            
//            let segmentCount = Int.random(in: 5...8) // Random number of zigzags
//            let segmentLength = hypot(target.x - start.x, target.y - start.y) / CGFloat(segmentCount)
//            
//            var currentPoint = start
//            var leaningDirection: CGFloat = Bool.random() ? -1 : 1  // Start leaning left or right
//            
//            for _ in 0..<segmentCount {
//                let xOffset = CGFloat.random(in: 10...30) * leaningDirection
//                let yOffset = segmentLength
//                
//                let nextPoint = CGPoint(x: currentPoint.x + xOffset, y: currentPoint.y + yOffset)
//                path.addLine(to: nextPoint)
//                
//                // Randomly decide if it should change direction
//                if Bool.random() {
//                    leaningDirection *= -1  // Switch left/right
//                }
//                
//                currentPoint = nextPoint
//            }
//            
//            path.addLine(to: target) // Final destination
//            
//            let duration = 5.0  // Time to reach target
//            let action = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
//            action.timingMode = .easeInEaseOut
//            return action
        }
    }
}
