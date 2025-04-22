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
    @Published var isLoading: Bool = false
    
    var players: [Player] {
        playerRepo.playersSubject.value
    }
    
    let playerRepo: PlayerRepositoryProtocol
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    init(authService: AuthenticationServiceProtocol,
         playerRepo: PlayerRepositoryProtocol) {
        self.authService = authService
        self.playerRepo = playerRepo
        
        isAuthenticated = authService.isAuthenticatedSubject.value
        
        authService.isAuthenticatedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isAuthenticated = $0
            }.store(in: &cancellables)
        
        if let lastPlayer = playerRepo.getLastUsed() {
            selectedPlayer = lastPlayer
        }
        
        playerRepo.playersSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] players in
                guard let self = self else { return }
                if players.isEmpty {
                    self.selectedPlayer = nil
                } else {
                    self.selectedPlayer = players.first
                }
                print("\(self.className): \(#function), selectedPlayer: \(self.selectedPlayer?.name ?? "None")")
            }.store(in: &cancellables)
    }
    
    func performGameCenterLogin() {
        guard !isLoading else {
            return
        }
        isLoading = true
        authService.authenticate { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if success {
                    // Create a player based on the Game Center user.
                    let gcPlayer = Player(
                        id: GKLocalPlayer.local.gamePlayerID,
                        name: GKLocalPlayer.local.alias,
                        type: .gameCenter,
                        lastUsed: Date()
                    )
                    self.playerRepo.save(gcPlayer)
                    self.selectedPlayer = gcPlayer
                    self.loginError = nil
                } else {
                    self.loginError = error?.localizedDescription ?? "Game Center authentication failed."
                }
            }
        }
    }
    
    func continueAsGuest(with name: String) {
        let guest = Player(name: name, type: .guest, lastUsed: Date())
        playerRepo.save(guest)
        selectedPlayer = guest
        isGuest = true
        loginError = nil
    }
    
    func saveSelectedPlayer() {
        playerRepo.save(selectedPlayer!)
    }
}
