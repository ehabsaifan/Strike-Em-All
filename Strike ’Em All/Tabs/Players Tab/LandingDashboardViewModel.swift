//
//  LandingDashboardViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI
import Combine
import GameKit

@MainActor
final class LandingDashboardViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var isSigningIn = false
    @Published var isAuthenticated = false
    @Published var navigateToGame = false
    @Published var currentPlayer: Player?
    
    private let auth: AuthenticationServiceProtocol
    private let repo: PlayerRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationServiceProtocol,
         playerRepo: PlayerRepositoryProtocol) {
        self.auth = authService
        self.repo = playerRepo
        
        // subscribe players
        repo.playersSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$players)
        
        // subscribe GC auth
        auth.isAuthenticatedSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }
    
    func signInGameCenter() {
        guard !isSigningIn,
              !isAuthenticated else {
            return
        }
        isSigningIn = true
        auth.authenticate { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isSigningIn = false
                self?.isAuthenticated = success
                if success { self?.saveCurrentGCPlayer() }
            }
        }
    }
    
    private func saveCurrentGCPlayer() {
        let lp = GKLocalPlayer.local
        let p = Player(gcPlayerID: lp.gamePlayerID,
                       id: lp.gamePlayerID.ckRecordNameSafe,
                       name: lp.alias,
                       type: .gameCenter,
                       lastUsed: .init())
        repo.save(p)
        currentPlayer = p
        navigateToGame = true
    }
    
    func addGuest(_ p: Player) {
        repo.save(p)
        navigateToGame = true
    }
    
    func startGame() {
        repo.save(currentPlayer!)
        navigateToGame = true
    }
}
