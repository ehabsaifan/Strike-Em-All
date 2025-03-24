//
//  GameScene.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/4/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let ballDiameter: CGFloat = GameViewModel.ballDiameter
    let ballStartY: CGFloat = GameViewModel.ballStartYSpacing
    
    private var ball: SKSpriteNode!
    // Flag to ensure callback is only called once per movement cycle.
    private var ballHasStopped = false
    // Use a magnitude threshold instead of per-component threshold.
    private let velocityThreshold: CGFloat = 3.0
    
    var onBallStopped: ((CGPoint) -> Void)?
    
    var ballStartPosition: CGPoint {
        CGPoint(x: frame.midX, y: frame.minY + ballStartY - ball.size.height/2)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        // Set up the physics world with edge boundaries
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
        
        ball = SKSpriteNode(imageNamed: "ball")
        
        if ball.texture == nil {
            // Fallback: create a circular shape if image is not available
            ball = SKSpriteNode(color: .blue, size: CGSize(width: ballDiameter, height: ballDiameter))
            ball.name = "ball"
        }
        
        ball.size = CGSize(width: ballDiameter, height: ballDiameter)
        ball.position = ballStartPosition
        // Set a high zPosition so the ball is rendered on top of other nodes
        ball.zPosition = 10
        
        // Set up physics for the ball
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballDiameter / 2)
        setDefaultBallphysicsBody()
        addChild(ball)
    }
    
    // This method lets the physics service update the ball’s position during dragging.
    func updateBallPosition(with offset: CGSize) {
        // For a seamless experience, update the ball’s position directly.
        // We assume the ball's "resting" position is ballStartPosition.
        ball.position = CGPoint(x: ballStartPosition.x + offset.width,
                                y: ballStartPosition.y + offset.height)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let velocity = ball.physicsBody?.velocity else { return }
        if !ballHasStopped,
           abs(velocity.dx) < velocityThreshold,
           abs(velocity.dy) < velocityThreshold {
            onBallStopped?(ball.position)
            ballHasStopped = true
        }
    }
    
    // Roll the ball to a random position between minY and maxY
    func rollBallToRandomPosition(maxY: CGFloat) {
        print("@@ Scene rollBallToRandomPosition: \(maxY)")
        let minY = ballStartPosition.y + 50 // a little bit above the original postion at min
        //print("@@ maxY: \(maxY),  ballStartPosition: \(ballStartPosition)")
        let maxMovement = maxY - ballStartPosition.y
        let targetY = CGFloat.random(in: minY...maxMovement)
        let targetPosition = CGPoint(x: ball.position.x, y: targetY)
        let duration: TimeInterval = 1.0
        let moveAction = SKAction.move(to: targetPosition, duration: duration)
        moveAction.timingMode = .easeOut
        ball.run(moveAction) { [weak self] in
            self?.onBallStopped?(targetPosition)
            self?.onBallStopped = nil
            self?.ballHasStopped = true
        }
    }
    
    func applyImpulse(_ impulse: CGVector, on object: RollingObject) {
        print("@@ Scene applyImpulse: \(impulse)")
        configureBall(for: object)
        
        if object.type == .crumpledPaper {
            // Base impulse
            ball.physicsBody?.applyImpulse(impulse)
            
            // Introduce random movement with small forces every frame
            let randomMotion = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run {
                        let randomX = CGFloat.random(in: -3...3)
                        let randomY = CGFloat.random(in: -1...1)
                        let randomImpulse = CGVector(dx: randomX, dy: randomY)
                        self.ball.physicsBody?.applyImpulse(randomImpulse)
                    },
                    SKAction.wait(forDuration: 0.01) // Adjust time between impulses
                ])
            )
            ball.run(randomMotion, withKey: "zigzagMotion")
        } else {
            ball.physicsBody?.applyImpulse(impulse)
        }
        ballHasStopped = false
    }
    
    func runMovementAction(_ action: SKAction) {
        ball.run(action) { [weak self] in
            guard let self = self else { return }
            onBallStopped?(ball.position)
            onBallStopped = nil
            ballHasStopped = true
        }
    }
    
    func resetBall() {
        print("@@ Scene resetBall")
        ball.position = ballStartPosition
        setDefaultBallphysicsBody()
        ball.removeAllActions()
        onBallStopped = nil
        ballHasStopped = true
    }
    
    private func configureBall(for rollingObject: RollingObject) {
        switch rollingObject.type {
        case .ironBall:
            ball.physicsBody?.mass = 1.2
            ball.physicsBody?.linearDamping = 0.7
            ball.physicsBody?.angularDamping = 0.6
        case .crumpledPaper:
            ball.physicsBody?.mass = 0.4  // Lighter than a ball
            ball.physicsBody?.linearDamping = CGFloat.random(in: 0.5...1.0)  // Unpredictable slowdown
            ball.physicsBody?.angularDamping = CGFloat.random(in: 0.3...0.8)  // Random rotational friction
            ball.physicsBody?.restitution = CGFloat.random(in: 0.2...0.5)  // Some bounce, but not too much
            ball.physicsBody?.friction = CGFloat.random(in: 0.5...0.9)  // Random rolling friction
        default:
            setDefaultBallphysicsBody()
        }
    }
    
    private func setDefaultBallphysicsBody() {
        ball.physicsBody?.velocity = .zero
        ball.physicsBody?.angularVelocity = .zero
        ball.physicsBody?.restitution = 0.2
        ball.physicsBody?.friction = 0.5
        ball.physicsBody?.mass = 0.6
        ball.physicsBody?.linearDamping = 0.4
        ball.physicsBody?.angularDamping = 0.3
        ball.physicsBody?.allowsRotation = true
    }
}
