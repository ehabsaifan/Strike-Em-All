//
//  GameRowProtocol.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

protocol GameRowProtocol {
    var leftMarking: MarkingState { get set }
    var rightMarking: MarkingState { get set }
    var displayContent: GameContent { get }
    var animationTrigger: Bool { get set }
    
    mutating func updateLeftMarking()
    mutating func updateRightMarking()
    mutating func reset()
}
