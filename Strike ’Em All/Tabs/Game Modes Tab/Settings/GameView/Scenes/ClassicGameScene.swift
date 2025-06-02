//
//  GameScene.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/4/25.
//

import SpriteKit
import GameplayKit

class ClassicGameScene: BaseGameScene {
    override var ballType: RollingObjectType {
        didSet {
            if activeBallNode != nil, ballsInMotionSet.isEmpty {
                activeBallNode!.texture = SKTexture(imageNamed:  ballType.imageName)
                configure(ball: activeBallNode!, as: ballType)
               // print("Setting ball type as \(ballType) \(activeBallNode!.physicsBody?.mass)")
            }
        }
    }

    /// Resets the ball to its starting position and restores default physics properties.
    override func restart() {
        super.restart()
        reset(activeBallNode!)
    }
}

class PersistingGameScene: BaseGameScene {
    private var allBallNodes = [SKSpriteNode]()
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        allBallNodes.append(activeBallNode!)
    }

    private func addNewBall(ofType type: RollingObjectType) {
       // print("addNewBall ballType: \(type)")
        let newBallNode = creatBallNode(type: type)
        allBallNodes.append(newBallNode)
        activeBallNode = newBallNode
        addChild(newBallNode)
       // print("ZizgzagMotion \(activeBallNode?.action(forKey: zigzagMotion))")
       // print("addNewBall \(activeBallNode!.physicsBody?.mass)")
        gameSceneDelegate?.created(newBallNode.ball)
    }
    
    /// Resets the ball to its starting position and restores default physics properties.
    override func restart() {
       // print("D- PersistingScene \(#function)")
        super.restart()
        allBallNodes.forEach({$0.removeFromParent()})
        allBallNodes = []
        ballsInMotionSet = []
        addNewBall(ofType: ballType)
    }
    
    /// Create a new ball node (at launch area)
    func addBall(of rollingObjectType: RollingObjectType) {
       // print("addBall ballType: \(rollingObjectType)")
        ballType = rollingObjectType
        addNewBall(ofType: rollingObjectType)
    }
}
