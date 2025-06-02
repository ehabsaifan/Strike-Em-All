//
//  PhysicsCategory.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/31/25.
//

import Foundation

struct PhysicsCategory {
    static let none: UInt32      = 0
    static let ball: UInt32      = 0x1 << 0    // 1
    static let border: UInt32    = 0x1 << 1    // 2
}
