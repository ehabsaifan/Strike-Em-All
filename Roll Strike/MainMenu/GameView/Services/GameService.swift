//
//  GameService.swift
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
    func markCell(at rowIndex: Int, forPlayer player: GameService.PlayerType)
    func checkForWinner() -> GameService.PlayerType?
    func reset()
}

class GameService: GameServiceProtocol {
    private(set) var rows: [GameRow] = []
    private(set) var rollingObject: RollingObject
    let contentProvider: GameContentProvider
    
    // Use dependency injection for the rolling object.
    init(rollingObject: RollingObject, contentProvider: GameContentProvider) {
        self.rollingObject = rollingObject
        self.contentProvider = contentProvider
    }
    
    enum PlayerType {
        case player1, player2
    }
    
    func startGame(with targets: [GameContent], cellEffect: CellEffect) {
        rows = targets.enumerated().map { index, target in
            GameRow(
                cellEffect: cellEffect,
                displayContent: target
            )
        }
        //print("@@ GameService started with rows: \(targets)")
    }
    
    func rollBall() -> Int? {
        print("@@ GameService rollBall()")
        guard !rows.isEmpty else {
            return nil
        }
        return rollingObject.roll(maxRows: rows.count)
    }
    
    func markCell(at rowIndex: Int, forPlayer player: PlayerType) {
        print("@@ GameService markCell at index: \(rowIndex)")
        guard rows.indices.contains(rowIndex) else {
            assertionFailure("cell index out of range")
            return
        }
        //print("@@ Markin cell at index: \(rowIndex)")
        var row = rows[rowIndex]
        switch player {
        case .player1:
            row.updateRightMarking()
        case .player2:
            row.updateLeftMarking()
        }
        rollingObject = row.cellEffect.affect(rollingObject: rollingObject)
        var new = rows
        new[rowIndex] = row
        rows = new
    }
    
    func checkForWinner() -> PlayerType? {
        print("@@ GameService checkForWinner")
        let playerOneScore = rows.filter { $0.rightMarking == .complete }.count
        let playerTwoScore = rows.filter { $0.leftMarking == .complete }.count
        
        if playerOneScore == rows.count {
            return .player1
        } else if playerTwoScore == rows.count {
            return .player2
        }
        return nil
    }
    
    func reset() {
        print("@@ GameService reset")
        rows = rows.map { row in
            var updatedRow = row
            updatedRow.reset()
            return updatedRow
        }
    }
}
