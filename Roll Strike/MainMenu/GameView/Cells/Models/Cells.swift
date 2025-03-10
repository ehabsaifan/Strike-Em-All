//
//  Cells.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

protocol CellEffect {
    var type: CellType { get }
    func affect(rollingObject: RollingObject) -> RollingObject
}

enum CellType {
    case fire
    case regular
    case wormhole
}

class RegularCell: CellEffect {
    var type: CellType = .regular
    
    func affect(rollingObject: RollingObject) -> RollingObject {
        // For demonstration, we just print a message.
        //print("RegularCell: \(rollingObject.name) is affected by nothing!")
        return rollingObject
    }
}

class FireCell: CellEffect {
    var type: CellType = .fire
    
    func affect(rollingObject: RollingObject) -> RollingObject {
        // For demonstration, we just print a message.
        //print("FireCell: \(rollingObject.name) is affected by fire!")
        return rollingObject
    }
}

class WormholeCell: CellEffect {
    var type: CellType = .wormhole
    
    func affect(rollingObject: RollingObject) -> RollingObject {
        // For demonstration, we just print a message.
        //print("WormholeCell: \(rollingObject.name) is affected by wormhole!")
        return rollingObject
    }
}
