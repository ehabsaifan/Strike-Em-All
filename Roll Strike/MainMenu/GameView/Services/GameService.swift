//
//  GameService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

class GameService: GameServiceProtocol {
    private(set) var rows: [GameRow] = []
    private(set) var rollingObject: RollingObject
    let contentProvider: GameContentProvider
    
    // Use dependency injection for the rolling object.
    init(rollingObject: RollingObject, contentProvider: GameContentProvider) {
            self.rollingObject = rollingObject
            self.contentProvider = contentProvider
        }
    
    enum Player {
        case player1, player2
    }
    
    func startGame(with targets: [GameContent], cellEffect: CellEffect) {
            rows = targets.enumerated().map { index, target in
                GameRow(
                    target: target,
                    cellEffect: cellEffect,
                    displayContent: contentProvider.getContent(for: index)
                )
            }
            print("@@ GameService started with rows: \(targets)")
        }
    
    func rollBall() -> Int? {
        print("@@ GameService rollBall()")
        guard !rows.isEmpty else {
            return nil
        }
        return rollingObject.roll(maxRows: rows.count)
    }
    
    func markCell(at rowIndex: Int, forPlayer player: Player) {
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
        rows[rowIndex] = row
    }
    
    func reset() {
        for index in 0..<rows.count {
            var row = rows[index]
            row.reset()
            rows[index] = row
        }
    }
}
