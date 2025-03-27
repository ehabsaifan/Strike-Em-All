//
//  SoundEvent.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/26/25.
//

import Foundation

enum SoundEvent: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case ropePull
    case ropeRelease
    case rolling
    case missStrike
    case hitStrike
    case winner
    
    func getSoundFileNames() -> [String] {
        switch self {
        case .ropePull:
            return ["rope_pull"]
        case .ropeRelease:
            return ["rope_release"]
        case .rolling:
            return ["rolling"]
        case .missStrike:
            return ["miss_strike_oops", "miss_strike_fart"]
        case .hitStrike:
            return ["hit_strike_waaw", "hit_strike_shaikh"]
        case .winner:
            return ["winner_enta_mallem"]
        }
    }
}
