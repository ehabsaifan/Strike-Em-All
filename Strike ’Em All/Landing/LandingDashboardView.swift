//
//  LandingDashboardView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI

struct LandingDashboardView: View {
    @Environment(\.di) private var di
    @StateObject private var vm: LandingDashboardViewModel
    
    @State private var showStatsFor: Player?
    @State private var showManageUsers = false
    @State private var showAddPlayer = false
    
    init(container: DIContainer) {
        _vm = StateObject(
            wrappedValue: LandingDashboardViewModel(
                authService: container.authService,
                playerRepo: container.playerRepo
            )
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    ScrollView {
                        SectionBlock(
                            title: "Players",
                            content: {
                                if vm.players.isEmpty {
                                    Button("Add Players") {
                                        showAddPlayer = true
                                    }
                                } else {
                                    ForEach(vm.players) { player in
                                        PlayerRow(
                                            player: player,
                                            onStats: { showStatsFor = player },
                                            onPlay: {
                                                vm.currentPlayer = player
                                                if player.type == .gameCenter && !vm.isAuthenticated {
                                                    vm.signInGameCenter()
                                                } else {
                                                    vm.startGame()
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        )
                    }
                    
                    Button {
                        vm.signInGameCenter()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text(vm.isAuthenticated ? "Signed In" : "Sign In with Game Center")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryColor.opacity(vm.isAuthenticated ? 0.6: 1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .shadow(color: Color.black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: -4)
                    .padding(.horizontal)
                    .disabled(vm.isSigningIn || vm.isAuthenticated)
                }
                // 2) GLOBAL spinner overlay
                if vm.isSigningIn {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Signing in…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Strike ’Em All")
            .navigationBarTitleDisplayMode(.inline)
            
            // 4. Edit Users toolbar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showManageUsers = true
                    }
                }
            }
            
            // Stats sheet
            .sheet(item: $showStatsFor) { player in
                PlayerStatsView(player: player, di: di) {
                    showStatsFor = nil
                    vm.currentPlayer = player
                    vm.startGame()
                }
                .environment(\.di, di)
            }
            
            // Manage players sheet
            .sheet(isPresented: $showManageUsers) {
                PlayerSelectionView(selectedPlayer: $vm.currentPlayer) {
                    if let p = vm.currentPlayer,
                       p.type == .gameCenter, !vm.isAuthenticated {
                        vm.signInGameCenter()
                    } else {
                        vm.startGame()
                    }
                    showManageUsers = false
                }
                .environment(\.di, di)
            }
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerView { name in
                    showAddPlayer = false
                    let player = Player(name: name, type: .guest, lastUsed: Date())
                    vm.currentPlayer = player
                    vm.addGuest(player)
                }
            }
            // Full-screen game flow
            .fullScreenCover(isPresented: $vm.navigateToGame) {
                MainMenuFlowView(loggedInPlayer: vm.currentPlayer!)
                    .environment(\.di, di)
            }
        }
    }
    
    // A little helper subview to keep the List row clean
    private struct PlayerRow: View {
        let player: Player
        let onStats: () -> Void
        let onPlay: () -> Void
        
        var body: some View {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryColor)
                        Text(player.lastUsed, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    SmallActionButton(
                        title: "Play",
                        icon: nil,
                        color: AppTheme.secondaryColor
                    ) {
                        onPlay()
                    }
                    .frame(width: 100)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .padding(.leading)
                }
                DashedDivider()
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())       // make entire row tappable
            .onTapGesture { onStats() }      // except the Play button
        }
    }
}
