//
//  AppState.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/24/25.
//

import SwiftUI
import Combine

final class AppState: ObservableObject {
    enum Tab { case players, modes, settings }
    
    @Published var selectedTab: Tab = .players
    @Published var navigateToGameSettings = false
    
    /// the player they chose in the Players tab
    @Published var currentPlayer: Player?
    
    /// the full configuration they chose in Modes→Settings
    @Published var currentConfig: GameConfiguration?
    
    /// once they tap “Play” here we can store it here
    func selectPlayingMode(for player: Player) {
        currentPlayer = player
        selectedTab = .modes
    }
    
    func selectPlayer() {
        selectedTab = .players
    }
    
    func startGame(with config: GameConfiguration) {
        guard currentPlayer != nil else {
            return
        }
        self.currentConfig = config
        navigateToGameSettings = true
    }
}

