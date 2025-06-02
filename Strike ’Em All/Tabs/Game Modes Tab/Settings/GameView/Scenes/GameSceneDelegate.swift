//
//  GameSceneDelegate.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/31/25.
//

import SpriteKit

let rollingObjectTypeKey = "rollingObjectType"

struct Ball: Codable, Hashable {
    let name: String
    let rollingObjectType: RollingObjectType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(rollingObjectType)
    }
}

protocol GameSceneDelegate: AnyObject {
    func created(_ ball: Ball)
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint)
    func allBallsCameToRest()
}

extension SKSpriteNode {
    var ball: Ball {
        let rollingObjectType = userData?[rollingObjectTypeKey] as? RollingObjectType ?? .crumpledPaper
        return Ball(name: name ?? "",
                    rollingObjectType: rollingObjectType)
    }
}
