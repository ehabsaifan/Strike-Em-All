//
//  GameServiceProtocol.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

protocol GameServiceProtocol {
    var rows: [GameRow] { get }
    var rollingObject: RollingObject { get }
    var contentProvider: GameContentProvider { get }
    
    func startGame(with targets: [GameContent], cellEffect: CellEffect)
    func rollBall() -> Int?
    func markCell(at rowIndex: Int, forPlayer player: GameService.Player)
    func reset()
}
