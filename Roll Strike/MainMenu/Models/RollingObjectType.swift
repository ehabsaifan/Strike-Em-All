//
//  RollingObjectType.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

enum RollingObjectType: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case crumpledPaper = "Crumpled Paper"
    case beachBall = "Beach Ball"
    case ironBall = "Iron Ball"
    
    var imageName: String {
        switch self {
        case .beachBall:
            "beach_ball"
        case .ironBall:
            "iron_ball"
        case .crumpledPaper:
            "crupmpled_paper_ball"
        }
    }
}

extension RollingObjectType {
    var rollingObject: RollingObject {
        switch self {
        case .beachBall:
            return Ball()
        case .crumpledPaper:
            return CrumpledPaper()
        case .ironBall:
            return IronBall()
        }
    }
}
