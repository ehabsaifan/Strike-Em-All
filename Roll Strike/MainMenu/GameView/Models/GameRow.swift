//
//  GameRow.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

struct GameRow: GameRowProtocol {
    let target: GameContent
    let cellEffect: CellEffect
    let displayContent: GameContent
    
    var leftMarking: MarkingState = .none
    var rightMarking: MarkingState = .none
    
    mutating func updateLeftMarking() {
        switch leftMarking {
        case .none:
            leftMarking = .half
        case .half:
            leftMarking = .complete
        case .complete:
            break
        }
    }
    
    mutating func updateRightMarking() {
        switch rightMarking {
        case .none:
            rightMarking = .half
        case .half:
            rightMarking = .complete
        case .complete:
            break
        }
    }

    mutating func reset() {
        leftMarking = .none
        rightMarking = .none
    }
}
