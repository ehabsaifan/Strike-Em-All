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
    @Published var rollingObjectType: RollingObjectType = .beachBall
    @Published var soundCategory: SoundCategory = .street
    @Published var volume: Float = 1.0 {
        didSet {
            SimpleDefaults.setValue(volume, forKey: .volumePref)
        }
    }
    @Published var selectedRowCount: Int = 5 {
        didSet {
            SimpleDefaults.setValue(selectedRowCount, forKey: .numberOfRows)
            print("ViewModel updated row count: \(selectedRowCount)")
        }
    }
    
    @Published var isWrapAroundEdgesEnabled = false
    
    init() {
        volume = SimpleDefaults.getValue(forKey: .volumePref, defaultValue: 1.0)
        selectedRowCount = SimpleDefaults.getValue(forKey: .numberOfRows, defaultValue: 5)
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
    
    func getSoundCategory() -> SoundCategory {
        return soundCategory
    }
}
