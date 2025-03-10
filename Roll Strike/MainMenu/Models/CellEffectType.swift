//
//  CellEffectType.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

enum CellEffectType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case regular = "Regular"
    case fire = "Fire"
    case wormhole = "Wormhole"
}
