//
//  RollingObjectType.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

enum RollingObjectType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case ball = "Ball"
    case fireBall = "FireBall"
    case crumpledPaper = "Crumpled Paper"
}
