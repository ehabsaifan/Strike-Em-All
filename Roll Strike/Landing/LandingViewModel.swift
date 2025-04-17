//
//  LandingViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import SwiftUI
import GameKit
import Combine

final class LandingViewModel: ObservableObject, ClassNameRepresentable {
    @Published var isAuthenticated: Bool = false
    @Published var loginError: String? = nil
    @Published var selectedPlayer: Player? = nil
    @Published var isGuest: Bool = false
    @Published var isLoading: Bool = false  // Indicates login is in progress
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        GameCenterService.shared.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
        
        if let lastPlayer = PlayerService.shared.getLastUsedPlayer() {
            selectedPlayer = lastPlayer
        }
        
        PlayerService.shared.$players
            .receive(on: DispatchQueue.main)
            .sink { [weak self] players in
                guard let self = self else { return }
                if players.isEmpty {
                    self.selectedPlayer = nil
                } else {
                    self.selectedPlayer = players.first
                }
                print("\(self.className): \(#function), selectedPlayer: \(self.selectedPlayer?.name ?? "None")")
            }
            .store(in: &cancellables)
    }
    
    func performGameCenterLogin() {
        guard !isLoading else {
            return
        }
        isLoading = true
        print("\(className): \(#function)\n")
        GameCenterService.shared.authenticateLocalPlayer { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                print("\(self.className): \(#function)\nsuccess: \(success)")
                if success {
                    // Create a player based on the Game Center user.
                    let gcPlayer = Player(
                        id: GKLocalPlayer.local.gamePlayerID,
                        name: GKLocalPlayer.local.alias,
                        type: .gameCenter,
                        lastUsed: Date()
                    )
                    PlayerService.shared.addOrUpdatePlayer(gcPlayer)
                    self.selectedPlayer = gcPlayer
                    self.loginError = nil
                } else {
                    self.loginError = error?.localizedDescription ?? "Game Center authentication failed."
                }
            }
        }
    }
    
    func continueAsGuest(with name: String) {
        print("\(className): \(#function)\nname: \(name)")
        let guest = Player(name: name, type: .guest, lastUsed: Date())
        PlayerService.shared.addOrUpdatePlayer(guest)
        selectedPlayer = guest
        isGuest = true
        loginError = nil
    }
}
