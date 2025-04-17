//
//  MainMenuViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import Foundation

class MainMenuViewModel: ObservableObject {
    @Published var playerMode: PlayerMode = .singlePlayer
    @Published var player1: Player = Player(name: "Player 1", type: .guest)
    @Published var player2: Player = Player(name: "Player 2", type: .guest)
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
        volume = SimpleDefaults.getValue(forKey: .volumePref) ?? 1.0
        selectedRowCount = SimpleDefaults.getValue(forKey: .numberOfRows) ?? 5
    }
    
    func getPlayer1() -> Player {
        return player1
    }
    
    func getPlayer2() -> Player {
        return playerMode == .againstComputer ? computer : player2
    }
    
    func getSoundCategory() -> SoundCategory {
        return soundCategory
    }
}
