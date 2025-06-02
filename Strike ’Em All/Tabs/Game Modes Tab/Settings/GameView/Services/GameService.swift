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
    func playerCompletedGame() -> GameService.PlayerType?
    func setRollingObject(_ newObject: RollingObject)
    func reset()
    
    func getStatus(for player: GameService.PlayerType, at index: Int) -> MarkingState
    func updateStatus(for player: GameService.PlayerType, at index: Int, with correctShotsCount: Int)
    func getRowsStatus(for player: GameService.PlayerType) -> (completedRows: Int, correctShots: Int)
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
    
    func getStatus(for player: PlayerType, at index: Int) -> MarkingState {
        guard index <= rows.count else {
            fatalError()
        }
        let row = rows[index]
        switch player {
        case .player1:
            return  row.leftMarking
        case .player2:
            return  row.rightMarking
        }
    }
    
    func updateStatus(for player: PlayerType, at index: Int, with correctShotsCount: Int) {
        guard index <= rows.count else {
            fatalError()
        }
        var state: MarkingState = .none
        if correctShotsCount == 1 {
            state = .half
        } else if correctShotsCount > 1 {
            state = .complete
        }
        
        var row = rows[index]
        switch player {
        case .player1:
            return  row.setLeftMarkingState(state)
        case .player2:
            return  row.setRightMarkingState(state)
        }
        var new = rows
        new[index] = row
        rows = new
    }
    
    func getRowsStatus(for player: PlayerType) -> (completedRows: Int, correctShots: Int) {
        var correctShots = 0
        var completedRows = 0
        for row in rows {
            switch player {
            case .player1:
                if row.leftMarking == .complete {
                    correctShots += 2
                    completedRows += 1
                }
                if row.leftMarking == .half {
                    completedRows += 1
                }
            case .player2:
                if row.rightMarking == .complete {
                    correctShots += 2
                    completedRows += 1
                }
                if row.rightMarking == .half {
                    completedRows += 1
                }
            }
        }
        return (completedRows: completedRows, correctShots: correctShots)
    }
    
    func playerCompletedGame() -> PlayerType? {
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
