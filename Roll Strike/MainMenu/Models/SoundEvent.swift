//
//  SoundEvent.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/26/25.
//

import Foundation

enum SoundEvent: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case ropePull = "rope_pull"
    case ropeRelease = "rope_release"
    case rolling
    case missStrike = "miss_strike"
    case hitStrike = "hit_strike"
    case winner
    
    func getSoundFileNames() -> [String] {
        var soundNames: [String]
        switch self {
        case .ropePull:
            soundNames = []
        case .ropeRelease:
            soundNames = []
        case .rolling:
            soundNames = []
        case .missStrike:
            soundNames = ["fart", "fart2", "fart3", "nooo", "ooh_snap", "ooh_snap_whoo", "oops", "oops_clumsy_me", "practice", "not_good", "this-sucks"]
        case .hitStrike:
            soundNames = ["brilliant", "magnificent", "outstanding_sir", "waw_cool", "waw_haha", "waw_no_way", "good_shot", "excellent", "excellent2", "excellent_hahaha", "bravo", "bravo2"]
        case .winner:
            soundNames = ["hahahaaa", "yaaay", "yaaay2", "great_job_buddy", "the_winner", "flawless_vectory"]
        }
        
        if soundNames.isEmpty {
            return [rawValue]
        } else {
            let mapped = soundNames.map {"\(rawValue)_\($0)"}
            return mapped
        }
    }
}
