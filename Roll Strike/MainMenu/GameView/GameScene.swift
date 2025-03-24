//
//  GameScene.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/4/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // These constants are pulled from the view model.
    let ballDiameter: CGFloat = GameViewModel.ballDiameter
    let ballStartY: CGFloat = GameViewModel.ballStartYSpacing
    
    private var ball: SKSpriteNode!
    // Flag to ensure callback is only called once per movement cycle.
    private var ballHasStopped = false
    // Use a magnitude threshold to detect when the ball has essentially stopped.
    private let velocityThreshold: CGFloat = 3.0
    
    // Callback to notify when the ball stops.
    var onBallStopped: ((CGPoint) -> Void)?
    
    // The starting position for the ball in the scene.
    var ballStartPosition: CGPoint {
        CGPoint(x: frame.midX, y: frame.minY + ballStartY - ball.size.height / 2)
    }
    
    var ballType: RollingObjectType = .ball {
        didSet {
            if ball != nil {
                ball.texture = SKTexture(imageNamed:  ballType.imageName)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        // Set up the physics world boundaries.
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
        
        // Create the ball node.
        ball = SKSpriteNode(texture: SKTexture(imageNamed: ballType.imageName))
        if ball.texture == nil {
            ball = SKSpriteNode(color: .blue, size: CGSize(width: ballDiameter, height: ballDiameter))
            ball.name = "ball"
        }
        
        ball.size = CGSize(width: ballDiameter, height: ballDiameter)
        ball.position = ballStartPosition
        ball.zPosition = 10
        
        // Set up the physics body for the ball.
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballDiameter / 2)
        setDefaultBallPhysicsBody()
        addChild(ball)
    }
    
    /// Called every frame. Detects when the ball’s velocity is low enough to consider it "stopped."
    override func update(_ currentTime: TimeInterval) {
        guard let velocity = ball.physicsBody?.velocity else { return }
        if !ballHasStopped,
           abs(velocity.dx) < velocityThreshold,
           abs(velocity.dy) < velocityThreshold {
            onBallStopped?(ball.position)
            ballHasStopped = true
        }
    }
    
    /// Updates the ball’s position directly during dragging.
    func updateBallPosition(with offset: CGSize) {
        ball.position = CGPoint(x: ballStartPosition.x + offset.width,
                                y: ballStartPosition.y + offset.height)
    }
    
    /// Rolls the ball to a random position (used for a random roll mode).
    func rollBallToRandomPosition(maxY: CGFloat) {
        print("@@ Scene rollBallToRandomPosition: \(maxY)")
        let minY = ballStartPosition.y + 50
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
    
    /// Applies an impulse to the ball. For crumpled paper, it adds a repeating "zigzag" random impulse to simulate erratic movement.
    func applyImpulse(_ impulse: CGVector, on object: RollingObject) {
        print("@@ Scene applyImpulse: \(impulse)")
        configureBall(for: object)
        
        if object.type == .crumpledPaper {
            // Apply the base impulse first.
            ball.physicsBody?.applyImpulse(impulse)
            
            // Run a repeating action that applies small random impulses.
            let randomMotion = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run {
                        let randomX = CGFloat.random(in: -3...3)
                        let randomY = CGFloat.random(in: -1...1)
                        let randomImpulse = CGVector(dx: randomX, dy: randomY)
                        self.ball.physicsBody?.applyImpulse(randomImpulse)
                    },
                    SKAction.wait(forDuration: 0.01)
                ])
            )
            ball.run(randomMotion, withKey: "zigzagMotion")
        } else {
            ball.physicsBody?.applyImpulse(impulse)
        }
        ballHasStopped = false
    }
    
    /// Runs a custom SKAction movement on the ball and then calls the callback when finished.
    func runMovementAction(_ action: SKAction) {
        ball.run(action) { [weak self] in
            guard let self = self else { return }
            self.onBallStopped?(self.ball.position)
            self.onBallStopped = nil
            self.ballHasStopped = true
        }
    }
    
    /// Resets the ball to its starting position and restores default physics properties.
    func resetBall() {
        print("@@ Scene resetBall")
        ball.position = ballStartPosition
        setDefaultBallPhysicsBody()
        ball.removeAllActions()
        onBallStopped = nil
        ballHasStopped = true
    }
    
    /// Configures the ball's physics properties based on the rolling object's type.
    private func configureBall(for rollingObject: RollingObject) {
        switch rollingObject.type {
        case .ironBall:
            ball.physicsBody?.mass = 1.2
            ball.physicsBody?.linearDamping = 0.7
            ball.physicsBody?.angularDamping = 0.6
        case .crumpledPaper:
            ball.physicsBody?.mass = 0.4
            ball.physicsBody?.linearDamping = CGFloat.random(in: 0.5...1.0)
            ball.physicsBody?.angularDamping = CGFloat.random(in: 0.3...0.8)
            ball.physicsBody?.restitution = CGFloat.random(in: 0.2...0.5)
            ball.physicsBody?.friction = CGFloat.random(in: 0.5...0.9)
        default:
            setDefaultBallPhysicsBody()
        }
    }
    
    /// Resets the ball's physics properties to default values.
    private func setDefaultBallPhysicsBody() {
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
