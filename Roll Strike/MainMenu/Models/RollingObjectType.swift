//
//  RollingObjectType.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

enum RollingObjectType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case beachBall = "Beach Ball"
    case ironBall = "Iron Ball"
    case crumpledPaper = "Crumpled Paper"
    
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
