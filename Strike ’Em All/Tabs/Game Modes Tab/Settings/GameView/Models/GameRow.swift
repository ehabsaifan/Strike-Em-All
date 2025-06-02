//
//  GameRow.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

struct GameRow: GameRowProtocol {
    let displayContent: GameContent
    
    var leftMarking: MarkingState = .none
    var rightMarking: MarkingState = .none
    var animationTrigger = false
    
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

    mutating func setRightMarkingState(_ state: MarkingState) {
        rightMarking = state
    }
    
    mutating func setLeftMarkingState(_ state: MarkingState) {
        leftMarking = state
    }
    
    mutating func reset() {
        leftMarking = .none
        rightMarking = .none
    }
}
