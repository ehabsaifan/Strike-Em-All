//
//  SpriteKitPhysicsService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/9/25.
//

import SpriteKit
import UIKit

protocol PhysicsServiceDelegate {
    func created(_ ball: Ball)
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint)
    func allBallsCameToRest()
}

protocol PhysicsServiceProtocol {
    var delegate: PhysicsServiceDelegate? { get set }
    
    func playerPulledBall(with offset: CGSize)
    func apply(_ impulse: CGVector)
    func setRollingObject(_ object: RollingObject)
    func setWrapAroundEnabled(_ enabled: Bool)
    func enableBallsBorder(_ enable: Bool)
    func restart()
}

class ClassicPhysicsService: PhysicsServiceProtocol {
    var delegate: PhysicsServiceDelegate?
    
    private var scene: ClassicGameScene?
    
    init(scene: ClassicGameScene) {
        self.scene = scene
        self.scene?.gameSceneDelegate = self
    }
    
    func playerPulledBall(with offset: CGSize) {
        scene?.playerPulledBall(with: offset)
    }
    
    func apply(_ impulse: CGVector) {
        guard let scene = scene else { return }
        scene.applyImpulse(impulse)
    }
    
    func setRollingObject(_ object: RollingObject) {
        scene?.ballType = object.type
    }
    
    func setWrapAroundEnabled(_ enabled: Bool) {
        scene?.wrapAroundEnabled = enabled
    }
    
    func enableBallsBorder(_ enable: Bool = false) {
        scene?.enableBallBorder = enable
    }
    
    func restart() {
        scene?.restart()
    }
}

// MARK: - GameSceneDelegate
extension ClassicPhysicsService: GameSceneDelegate {
    func allBallsCameToRest() {
        delegate?.allBallsCameToRest()
    }
    
    func created(_ ball: Ball) {
        delegate?.created(ball)
    }
    
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint) {
        delegate?.ballStoppedMoving(ball, at: position)
    }
}

class PersistingPhysicsService: PhysicsServiceProtocol {
    var delegate: PhysicsServiceDelegate?
    
    private var scene: PersistingGameScene?
    
    init(scene: PersistingGameScene) {
        self.scene = scene
        self.scene?.gameSceneDelegate = self
    }
    
    func addBall(of rollingObjectType: RollingObjectType) {
        scene?.addBall(of: rollingObjectType)
    }
    
    func playerPulledBall(with offset: CGSize) {
        scene?.playerPulledBall(with: offset)
    }
    
    func apply(_ impulse: CGVector) {
        guard let scene = scene else { return }
        scene.applyImpulse(impulse)
    }
    
    func setRollingObject(_ object: RollingObject) {
        scene?.ballType = object.type
    }
    
    func setWrapAroundEnabled(_ enabled: Bool) {
        scene?.wrapAroundEnabled = enabled
    }
    
    func enableBallsBorder(_ enable: Bool = false) {
        scene?.enableBallBorder = enable
    }
    
    func restart() {
        scene?.restart()
    }
}

// MARK: - GameSceneDelegate
extension PersistingPhysicsService: GameSceneDelegate {
    func allBallsCameToRest() {
        delegate?.allBallsCameToRest()
    }
    
    func created(_ ball: Ball) {
        delegate?.created(ball)
    }
    
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint) {
        delegate?.ballStoppedMoving(ball, at: position)
    }
}
