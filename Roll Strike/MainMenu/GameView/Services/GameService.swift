//
//  GameService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

protocol GameServiceProtocol {
    var rows: [GameRow] { get }
    var rollingObject: RollingObject { get }
    var contentProvider: GameContentProvider { get }
    
    func startGame(with targets: [GameContent])
    func markCell(at rowIndex: Int, forPlayer player: GameService.PlayerType) -> Bool
    func checkForWinner() -> GameService.PlayerType?
    func setRollingObject(_ newObject: RollingObject)
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
    
    func startGame(with targets: [GameContent]) {
        rows = targets.enumerated().map { index, target in
            GameRow(
                displayContent: target
            )
        }
    }
    
    func markCell(at rowIndex: Int, forPlayer player: PlayerType) -> Bool {
        guard rows.indices.contains(rowIndex) else {
            assertionFailure("cell index out of range")
            return false
        }
        var row = rows[rowIndex]
        let prevMarking: MarkingState
        let newMarking: MarkingState
        switch player {
        case .player1:
            prevMarking = row.leftMarking
            row.updateLeftMarking()
            newMarking = row.leftMarking
        case .player2:
            prevMarking = row.rightMarking
            row.updateRightMarking()
            newMarking = row.rightMarking
        }
        var new = rows
        new[rowIndex] = row
        rows = new
        return newMarking != prevMarking
    }
    
    func checkForWinner() -> PlayerType? {
        let playerOneScore = rows.filter { $0.leftMarking == .complete }.count
        let playerTwoScore = rows.filter { $0.rightMarking == .complete }.count
        
        if playerOneScore == rows.count {
            return .player1
        } else if playerTwoScore == rows.count {
            return .player2
        }
        return nil
    }
    
    func setRollingObject(_ newObject: RollingObject) {
        rollingObject = newObject
    }
    
    func reset() {
        rows = rows.map { row in
            var updatedRow = row
            updatedRow.reset()
            return updatedRow
        }
    }
}
