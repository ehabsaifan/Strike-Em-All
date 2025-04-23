//
//  PlayerModeSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/16/25.
//

import SwiftUI

struct PlayerModeSelectionView: View {
    @Environment(\.di) private var di
    @Binding var config: GameConfiguration
    @State private var isSigningIn = false
    @State private var showingSignIn = false
    @State private var showingAdd = false
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Player Mode")
                    .foregroundColor(AppTheme.primaryColor)) {
                        Picker("Mode", selection: $config.playerMode) {
                            ForEach(PlayerMode.allCases, id: \.self) { m in
                                Text(m.title).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                
                Section(header: Text("Logged-In Player")
                    .foregroundColor(AppTheme.primaryColor)) {
                        VStack {
                            HStack {
                                Text(config.player1.name)
                                Spacer()
                                Text("You").foregroundColor(.secondary)
                            }
                            if config.player1.type == .gameCenter && di.gameCenter.isAuthenticatedSubject.value {
                                HStack(spacing: 16) {
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            di.gameCenter.showLeaderboard()
                                        }) {
                                            Text("Leaderboard")
                                                .font(.headline)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(AppTheme.secondaryColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button(action: {
                                            di.gameCenter.showAchievements()
                                        }) {
                                            Text("Achievements")
                                                .font(.headline)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(AppTheme.secondaryColor)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                
                if config.playerMode == .twoPlayers {
                    SecondPlayerSection(selected: $config.player2,
                                        loggedIn: config.player1,
                                        playerRepo: di.playerRepo,
                                        authService: di.authService,
                                        gameCenter: di.gameCenter) {
                        isSigningIn = true
                    } onEndSignIn: {
                        isSigningIn = false
                    }
                    
                }
            }
            .accentColor(AppTheme.primaryColor)
            .navigationTitle("Setup Players")
            
            // only this overlay floats on top
            if isSigningIn {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Signing in…")
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            }
        }
    }
}

private struct SecondPlayerSection: View {
    @Binding var selected: Player?
    
    let loggedIn: Player
    let playerRepo: PlayerRepositoryProtocol
    let authService: AuthenticationServiceProtocol
    let gameCenter: GameCenterProtocol
    let onBeginSignIn: () -> Void
    let onEndSignIn:   () -> Void
    
    @State private var showingSignIn = false
    @State private var showingAdd    = false
    
    var body: some View {
        Section(header: Text("Select Second Player")
            .foregroundColor(AppTheme.primaryColor)) {
                let available = playerRepo.playersSubject.value
                    .filter { $0.id != loggedIn.id }
                    .sorted { $0.lastUsed > $1.lastUsed }
                
                ForEach(available, id: \.id) { p in
                    VStack {
                        HStack {
                            Text(p.name)
                            Spacer()
                            if selected?.id == p.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // if they’re a GC user but not authed, show alert
                            if p.type == .gameCenter &&
                                !authService.isAuthenticatedSubject.value {
                                showingSignIn = true
                                selected = p
                            } else {
                                selected = p
                            }
                        }
                        
                        if p.type == .gameCenter && authService.isAuthenticatedSubject.value {
                            HStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        gameCenter.showLeaderboard()
                                    }) {
                                        Text("Leaderboard")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(AppTheme.secondaryColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        gameCenter.showAchievements()
                                    }) {
                                        Text("Achievements")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(AppTheme.secondaryColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                Button {
                    showingAdd = true
                } label: {
                    Label("Add New Player", systemImage: "plus.circle")
                        .foregroundColor(AppTheme.secondaryColor)
                }
                .sheet(isPresented: $showingAdd) {
                    AddPlayerView { name in
                        let newP = Player(name: name, type: .guest, lastUsed: Date())
                        playerRepo.save(newP)
                        selected = newP
                        showingAdd = false
                    }
                }
            }
            .alert("Game Center Sign-In Required",
                   isPresented: $showingSignIn) {
                Button("Sign In") {
                    // start loader
                    onBeginSignIn()
                    authService.authenticate { success, _ in
                        DispatchQueue.main.async {
                            // stop loader
                            onEndSignIn()
                            if !success {
                                selected = nil
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    selected = nil
                }
            } message: {
                Text("Please sign in to Game Center for this player.")
            }
    }
}

private struct SmallActionButton: View {
    let title: String, icon: String, color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "")
                .font(.subheadline)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

