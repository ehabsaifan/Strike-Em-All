//
//  PlayerModeSelectionView.swift
//  Strike ’Em All
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
            ScrollView {
                VStack(spacing: 0) {
                    SectionBlock(
                        title: "Player Mode",
                        content: {
                            CustomSegmentedControl(
                                selectedSegment: $config.playerMode,
                                items: PlayerMode.allCases,
                                label: { $0.title },
                                settings: CustomSegmentedControlSettings()
                            )
                        }
                    )
                    Spacer()
                    SectionBlock(
                        title: "Logged-In Player",
                        content: {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(config.player1.name)
                                    Spacer()
                                    Text("You")
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                                
                                if config.player1.type == .gameCenter
                                    && di.gameCenter.isAuthenticatedSubject.value
                                {
                                    HStack(spacing: 12) {
                                        SmallActionButton(
                                            title: "Leaderboard",
                                            icon: nil,
                                            color: AppTheme.secondaryColor
                                        ) {
                                            di.gameCenter.showLeaderboard()
                                        }
                                        SmallActionButton(
                                            title: "Achievements",
                                            icon: nil,
                                            color: AppTheme.secondaryColor
                                        ) {
                                            di.gameCenter.showAchievements()
                                        }
                                    }
                                }
                            }
                        }
                    )
                    
                    // MARK: – Second Player Section (conditionally)
                    if config.playerMode == .twoPlayers {
                        Spacer()
                        SectionBlock(
                            title: "Select Second Player",
                            content: {
                                VStack(spacing: 12) {
                                    ForEach(
                                        di.playerRepo.playersSubject.value
                                            .filter { $0.id != config.player1.id }
                                            .sorted(by: { $0.lastUsed > $1.lastUsed }),
                                        id: \.id
                                    ) { p in
                                        HStack {
                                            Text(p.name)
                                            Spacer()
                                            if config.player2?.id == p.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppTheme.secondaryColor)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if p.type == .gameCenter
                                                && !di.authService.isAuthenticatedSubject.value
                                            {
                                                showingSignIn = true
                                                config.player2 = p
                                            } else {
                                                config.player2 = p
                                            }
                                        }
                                        
                                        if p.type == .gameCenter
                                            && di.authService.isAuthenticatedSubject.value
                                        {
                                            HStack(spacing: 12) {
                                                SmallActionButton(
                                                    title: "Leaderboard",
                                                    icon: nil,
                                                    color: AppTheme.secondaryColor
                                                ) {
                                                    di.gameCenter.showLeaderboard()
                                                }
                                                SmallActionButton(
                                                    title: "Achievements",
                                                    icon: nil,
                                                    color: AppTheme.secondaryColor
                                                ) {
                                                    di.gameCenter.showAchievements()
                                                }
                                            }
                                        }
                                        Divider()
                                    }
                                    
                                    Button(action: { showingAdd = true }) {
                                        Label("Add New Player", systemImage: "plus.circle")
                                            .foregroundColor(AppTheme.secondaryColor)
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(AppTheme.secondaryColor, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        )
                        .sheet(isPresented: $showingAdd) {
                            AddPlayerView { name in
                                let newP = Player(name: name, type: .guest, lastUsed: Date())
                                di.playerRepo.save(newP)
                                config.player2 = newP
                                showingAdd = false
                            }
                        }
                        .alert(
                            "Game Center Sign-In Required",
                            isPresented: $showingSignIn
                        ) {
                            Button("Sign In") {
                                isSigningIn = true
                                di.authService.authenticate { success, _ in
                                    isSigningIn = false
                                    if !success { config.player2 = nil }
                                }
                            }
                            Button("Cancel", role: .cancel) {
                                config.player2 = nil
                            }
                        } message: {
                            Text("Please sign in to Game Center for this player.")
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            
            // Signing-in overlay
            if isSigningIn {
                ZStack {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.3)
                        
                        Text("Signing in…")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
            }
        }
        .navigationTitle("Setup Players")
        .navigationBarTitleDisplayMode(.inline)
    }
}
