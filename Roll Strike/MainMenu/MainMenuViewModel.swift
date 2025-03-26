//
//  MainMenuViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

class MainMenuViewModel: ObservableObject {
    @Published var gameMode: GameMode = .singlePlayer
    @Published var player1Name: String = ""
    @Published var player2Name: String = ""
    @Published var showGameView: Bool = false
    @Published var selectedRollingObjectType: RollingObjectType = .beachBall
    @Published var selectedCellEffectType: CellEffectType = .regular

    private let contentProvider: GameContentProvider
    
    init(contentProvider: GameContentProvider) {
        self.contentProvider = contentProvider
    }

    func getPlayer1() -> Player {
        let name = player1Name.isEmpty ? "Player 1" : player1Name
        return .player(name: name)
    }

    func getPlayer2() -> Player {
        guard gameMode != .againstComputer else {
            return .computer
        }
        let name = player2Name.isEmpty ? "Player 2" : player2Name
        return .player(name: name)
    }

    func getTargets() -> [GameContent] {
        return contentProvider.getSelectedContents()
    }

    func createRollingObject() -> RollingObject {
        switch selectedRollingObjectType {
        case .beachBall:
            return Ball()
        case .crumpledPaper:
            return CrumpledPaper()
        case .ironBall:
            return IronBall()
        }
    }
}
