//
//  BaseGameScene.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/29/25.
//

import SpriteKit
import GameplayKit

class BaseGameScene: SKScene {
    let zigzagMotion = "zigzagMotion"
    // These constants are pulled from the view model.
    let ballDiameter: CGFloat = GameViewConstants.ballDiameter
    let ballStartY: CGFloat = GameViewConstants.ballStartYSpacing
    // Use a magnitude threshold to detect when the ball has essentially stopped.
    let velocityThreshold: CGFloat = 4.0
    
    var activeBallNode: SKSpriteNode?
    var wrapAroundEnabled: Bool = false
    var enableBallBorder = false
    
    var ballType: RollingObjectType = .beachBall {
        didSet {
            //print("Setting ballType: \(ballType)")
        }
    }
    var borderNode: SKShapeNode!
    var ballsInMotionSet: Set<SKSpriteNode> = []
    var ballsCount = 0
    
    weak var gameSceneDelegate: GameSceneDelegate?
    private var shouldReportAllBallsStopped = false
    var ballRadius: CGFloat {
       ballDiameter / 2
   }
    
    // The starting position for the ball in the scene.
    var ballStartPosition: CGPoint {
        CGPoint(x: frame.midX, y: frame.minY + ballStartY - ballRadius)
    }
   
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        buildBorder()
        // Set up the physics world boundaries.
        if wrapAroundEnabled {
            physicsBody = nil
        } else {
            let edge = SKPhysicsBody(edgeLoopFrom: bounds)
            edge.categoryBitMask = PhysicsCategory.border
            edge.friction = 0
            physicsBody = edge
        }
        updateBorderStyle()
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        activeBallNode = creatBallNode(type: ballType)
        addChild(activeBallNode!)
        //print("ZizgzagMotion \(activeBallNode?.action(forKey: zigzagMotion))")
        //print("Current active ball of type \(ballType) -> \(activeBallNode!.physicsBody?.mass)")
        gameSceneDelegate?.created(activeBallNode!.ball)
    }
    
    /// Applies an impulse to the ball. For crumpled paper, it adds a repeating "zigzag" random impulse to simulate erratic movement.
    func applyImpulse(_ impulse: CGVector) {
        guard let activeBallNode else { return }
        shouldReportAllBallsStopped = true
        if activeBallNode.action(forKey: zigzagMotion) != nil {
            activeBallNode.removeAction(forKey: zigzagMotion)
        }
        
        let type = activeBallNode.userData?[rollingObjectTypeKey] as? RollingObjectType ?? ballType
        activeBallNode.removeAllActions()
        //print("ZizgzagMotion \(activeBallNode.action(forKey: zigzagMotion))")
        if type == .crumpledPaper {
            // Apply the base impulse first.
            activeBallNode.physicsBody?.applyImpulse(impulse)
            // Schedule periodic small perturbations to the current velocity.
            let perturbationAction = getPerturbationActionOnActiveBall()
            activeBallNode.run(perturbationAction, withKey: zigzagMotion)
           // print("Zigzag is on")
        } else {
            activeBallNode.physicsBody?.applyImpulse(impulse)
        }
        // Apply some rotational
        activeBallNode.physicsBody?.applyAngularImpulse(CGFloat.random(in: 0.02...0.10))
        ballsInMotionSet.insert(activeBallNode)
    }
    
    func getPerturbationActionOnActiveBall() -> SKAction {
        // Schedule periodic small perturbations to the current velocity.
        let perturbationAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.1),  // Adjust frequency as needed.
                SKAction.run { [weak self] in
                    guard let self = self,
                          let activeBallNode = self.activeBallNode,
                          let currentVelocity = activeBallNode.physicsBody?.velocity else { return }
                    if let data = activeBallNode.userData,
                       let currentType = data[rollingObjectTypeKey] as? RollingObjectType,
                       currentType != .crumpledPaper {
                        // If the type is no longer crumpledPaper,
                        // immediately stop this action:
                        activeBallNode.removeAction(forKey: zigzagMotion)
                        return
                    }
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
                    self.activeBallNode?.physicsBody?.applyImpulse(lateralImpulse)
                }
            ])
        )
        
        return perturbationAction
    }
    
    func creatBallNode(type: RollingObjectType) -> SKSpriteNode {
        // print("creating ball of type: \(type)")
        var ball = SKSpriteNode(texture: SKTexture(imageNamed: type.imageName))
        ballsCount += 1
        if ball.texture == nil {
            ball = SKSpriteNode(color: .blue, size: CGSize(width: ballDiameter, height: ballDiameter))
        }
        ball.name = "ball - \(ballsCount)"
        ball.userData = [rollingObjectTypeKey: type]
        ball.size = CGSize(width: ballDiameter, height: ballDiameter)
        ball.position = ballStartPosition
        ball.zPosition = 10
        
        // Set up the physics body for the ball.
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballDiameter / 2)
        ball.removeAction(forKey: zigzagMotion)
        configure(ball: ball, as: type)
        
        if enableBallBorder {
            let border = SKShapeNode(circleOfRadius: ballDiameter/2)
            border.strokeColor = (ballsCount%2) == 0 ? .blue : .red
            border.lineWidth = 1.0          // <-- customize thickness here
            border.fillColor = .clear        // just an outline, no fill
            border.zPosition = ball.zPosition + 1
            border.position = CGPoint.zero
            ball.addChild(border)
        }
        return ball
    }

    /// Updates the ball’s position directly during dragging.
    func playerPulledBall(with offset: CGSize) {
        guard let activeBallNode else { return }
        activeBallNode.position = CGPoint(x: ballStartPosition.x + offset.width,
                                      y: ballStartPosition.y - offset.height)
    }

    func buildBorder() {
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
    
    func updateBorderStyle() {
        guard wrapAroundEnabled else {
            return
        }
        borderNode.strokeColor = .black.withAlphaComponent(0.8)
        borderNode.glowWidth   = 12
    }

    func wrapAround(_ ball: SKSpriteNode, velocity: CGVector) {
        guard wrapAroundEnabled else {
            return
        }
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
    
    /// Called every frame. Detects when the ball’s velocity is low enough to consider it "stopped."
    override func update(_ currentTime: TimeInterval) {
        ballsInMotionSet.forEach({ node in
            guard let velocity = node.physicsBody?.velocity else { return }
            wrapAround(node, velocity: velocity)
            guard abs(velocity.dx) < velocityThreshold,
                  abs(velocity.dy) < velocityThreshold else {
                return
            }
           
            gameSceneDelegate?.ballStoppedMoving(node.ball, at: node.position)
            ballsInMotionSet.remove(node)
        })
        if shouldReportAllBallsStopped,
            ballsInMotionSet.isEmpty {
            gameSceneDelegate?.allBallsCameToRest()
            shouldReportAllBallsStopped = false
        }
    }

    /// Configures the ball's physics properties based on the rolling object's type.
    func configure(ball: SKSpriteNode, as type: RollingObjectType) {
        //print("Configuring ball as \(type)")
        if type != .crumpledPaper {
            if ball.action(forKey: zigzagMotion) != nil {
                ball.removeAction(forKey: zigzagMotion)
            }
        }
        switch type {
        case .ironBall:
            ball.physicsBody?.mass = 1.1
            ball.physicsBody?.linearDamping = 0.7
            ball.physicsBody?.angularDamping = 0.6
            ball.physicsBody?.friction = 0.3
        case .crumpledPaper:
            ball.physicsBody?.mass = 0.6
            ball.physicsBody?.linearDamping = CGFloat.random(in: 0.5...1.0)
            ball.physicsBody?.angularDamping = CGFloat.random(in: 0.3...0.8)
            
            ball.physicsBody?.restitution = CGFloat.random(in: 0.2...0.5)
            ball.physicsBody?.friction = CGFloat.random(in: 0.6...0.9)
            
        default:
            setDefaultPhysicsBody(for: ball)
        }
        
        ball.physicsBody?.allowsRotation = true
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        ball.physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.border
        ball.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    /// Resets the ball's physics properties to default values.
    private func setDefaultPhysicsBody(for ball: SKSpriteNode) {
        ball.physicsBody?.velocity = .zero
        ball.physicsBody?.angularVelocity = .zero
        ball.physicsBody?.restitution = 0.2
        ball.physicsBody?.friction = 0.5
        
        ball.physicsBody?.mass = 0.8
        ball.physicsBody?.linearDamping = 0.4
        ball.physicsBody?.angularDamping = 0.3
    }
    
    func reset(_ ball: SKSpriteNode) {
        ball.position = ballStartPosition
        configure(ball: ball, as: ballType)
        if ballType != .crumpledPaper {
            ball.removeAction(forKey: zigzagMotion)
        }
        ball.removeAllActions()
       // print("reset ball as \(ball.physicsBody?.mass)")
    }
    
    func restart() {
        ballsInMotionSet = []
        ballsCount = 0
    }
}

//MARK: - SKPhysicsContactDelegate
extension BaseGameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // This is called whenever ANY two bodies whose categoryBitMask/contactTestBitMask overlap begin touching.
        // We only care about Ball<->Ball interactions, so:
        let a = contact.bodyA
        let b = contact.bodyB
        
        if a.categoryBitMask == PhysicsCategory.ball && b.categoryBitMask == PhysicsCategory.ball {
            // Two balls have collided. You can, for example, highlight them, play a sound,
            // or schedule a callback. Typically, you'd do nothing here except maybe record that a collision happened.
            // If you want to know “after collision, does one ball move another?”—SpriteKit handles the impulse automatically.
            // But you can store this fact if you want:
            if let ballNodeA = a.node as? SKSpriteNode,
               let ballNodeB = b.node as? SKSpriteNode {
                // e.g.:
                //print("\(ballNodeA.name) collided with \(ballNodeB.name)")
                ballsInMotionSet.insert(ballNodeA)
                ballsInMotionSet.insert(ballNodeB)
            }
        }
    }
}
