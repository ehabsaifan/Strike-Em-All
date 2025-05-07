//
//  GameScene.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/4/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // These constants are pulled from the view model.
    let ballDiameter: CGFloat = GameViewModel.ballDiameter
    let ballStartY: CGFloat = GameViewModel.ballStartYSpacing
    
    private var borderNode: SKShapeNode!
    private var ball: SKSpriteNode!
    // Flag to ensure callback is only called once per movement cycle.
    private var ballHasStopped = false
    // Use a magnitude threshold to detect when the ball has essentially stopped.
    private let velocityThreshold: CGFloat = 4.0
    
    private var ballRadius: CGFloat {
        ball.size.height / 2
    }
    
    // Callback to notify when the ball stops.
    var onBallStopped: ((CGPoint) -> Void)?
    
    var wrapAroundEnabled: Bool = false
    
    // The starting position for the ball in the scene.
    var ballStartPosition: CGPoint {
        CGPoint(x: frame.midX, y: frame.minY + ballStartY - ballRadius)
    }
    
    var ballType: RollingObjectType = .beachBall {
        didSet {
            if ball != nil {
                ball.texture = SKTexture(imageNamed:  ballType.imageName)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        buildBorder()
        
        // Set up the physics world boundaries.
        if wrapAroundEnabled {
            physicsBody = nil
        } else {
            physicsBody = SKPhysicsBody(edgeLoopFrom: bounds)
        }
        updateBorderStyle()
        
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
        ball.color = .yellow
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
        
        if wrapAroundEnabled {
            let minX = frame.minX
            let maxX = frame.maxX
            let minY = frame.minY
            let maxY = frame.maxY
            let ballXPos = floor(ball.position.x)
            let ballYPos = floor(ball.position.y)
            var newPosition = ball.position
            var didWrap = false
            
            if ballXPos - ballRadius <= minX, velocity.dx < 0 {
                newPosition.x = maxX - ballRadius
                newPosition.y = abs(maxY - ballYPos)
                didWrap = true
            } else if ballXPos + ballRadius >= maxX, velocity.dx > 0 {
                newPosition.x = minX + ballRadius
                newPosition.y = abs(maxY - ballYPos)
                didWrap = true
            } else if ballYPos - ballRadius <= minY, velocity.dy < 0 {
                newPosition.y = maxY - ballRadius
                newPosition.x = abs(maxX - ballXPos)
                didWrap = true
            } else if ballYPos + ballRadius >= maxY, velocity.dy > 0 {
                newPosition.y = minY + ballRadius
                newPosition.x = abs(maxX - ballXPos)
                didWrap = true
            }
            
            if didWrap {
                ball.position = newPosition
            }
        }
    }
    
    /// Configures the ball's physics properties based on the rolling object's type.
    private func configureBall(for rollingObject: RollingObject) {
        switch rollingObject.type {
        case .ironBall:
            ball.physicsBody?.mass = 1.1
            ball.physicsBody?.linearDamping = 0.7
            ball.physicsBody?.angularDamping = 0.6
        case .crumpledPaper:
            ball.physicsBody?.mass = 0.6
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
        ball.physicsBody?.mass = 0.8
        ball.physicsBody?.linearDamping = 0.4
        ball.physicsBody?.angularDamping = 0.3
        ball.physicsBody?.allowsRotation = true
    }
    
    private func buildBorder() {
        guard wrapAroundEnabled else {
            return
        }
        let rect = CGRect(origin: .zero, size: size)
        // Pick whatever corner radius looks right for your device
        let cornerRadius: CGFloat = 30
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        borderNode = SKShapeNode(path: path)
        borderNode.position    = CGPoint(x: 0, y: 0)
        borderNode.lineWidth   = 1
        borderNode.zPosition   = 100   // above everything else
        addChild(borderNode)
        updateBorderStyle()      // set
    }
    
    private func updateBorderStyle() {
        guard wrapAroundEnabled else {
            return
        }
        borderNode.strokeColor = .black.withAlphaComponent(0.8)
        borderNode.glowWidth   = 12
    }
}

extension GameScene {
    /// Updates the ball’s position directly during dragging.
    func updateBallPosition(with offset: CGSize) {
        guard ball != nil else { return }
        ball.position = CGPoint(x: ballStartPosition.x + offset.width,
                                y: ballStartPosition.y - offset.height)
    }
    
    /// Applies an impulse to the ball. For crumpled paper, it adds a repeating "zigzag" random impulse to simulate erratic movement.
    func applyImpulse(_ impulse: CGVector, on object: RollingObject) {
        configureBall(for: object)
        
        if object.type == .crumpledPaper {
            // Apply the base impulse first.
            ball.physicsBody?.applyImpulse(impulse)
            
            // Schedule periodic small perturbations to the current velocity.
            let perturbationAction = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.1),  // Adjust frequency as needed.
                    SKAction.run { [weak self] in
                        guard let self = self,
                              let currentVelocity = self.ball.physicsBody?.velocity else { return }
                        
                        // Compute the current velocity angle.
                        let currentAngle = atan2(currentVelocity.dy, currentVelocity.dx)
                        
                        // Choose a small random delta (in radians) - about ±4° (0.035 radians).
                        let deltaAngle = CGFloat.random(in: -0.07...0.07)
                        let newAngle = currentAngle + deltaAngle
                        
                        // Compute the magnitude (speed) of the current velocity.
                        let speed = hypot(currentVelocity.dx, currentVelocity.dy)
                        
                        // Determine the target velocity vector after the small change.
                        let targetVelocity = CGVector(dx: speed * cos(newAngle), dy: speed * sin(newAngle))
                        
                        // Compute the change required.
                        let deltaVx = targetVelocity.dx - currentVelocity.dx
                        let deltaVy = targetVelocity.dy - currentVelocity.dy
                        let lateralImpulse = CGVector(dx: deltaVx, dy: deltaVy)
                        
                        // Apply the small lateral impulse.
                        self.ball.physicsBody?.applyImpulse(lateralImpulse)
                    }
                ])
            )
            ball.run(perturbationAction, withKey: "zigzagMotion")
        } else {
            ball.physicsBody?.applyImpulse(impulse)
        }
        // Apply some rotational
        ball.physicsBody?.applyAngularImpulse(CGFloat.random(in: 0.02...0.10))
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
        ball.position = ballStartPosition
        setDefaultBallPhysicsBody()
        ball.removeAllActions()
        onBallStopped = nil
        ballHasStopped = true
    }
}
