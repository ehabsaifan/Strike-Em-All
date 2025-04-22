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
    @State private var showAddSheet = false
    
    var body: some View {
        Form {
            Section(header: Label("Player Mode", systemImage: "gamecontroller.fill")
                .foregroundColor(AppTheme.primaryColor)) {
                    Picker("", selection: $config.playerMode) {
                        ForEach(Array(PlayerMode.allCases), id: \.self) { mode in
                            mode.label
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }
            
            Section(header: Label("Logged-In Player", systemImage: "person.fill")
                .foregroundColor(AppTheme.primaryColor)) {
                    HStack {
                        Text(config.player1.name)
                        Spacer()
                        Text("You").foregroundColor(.secondary)
                    }
                    if config.player1.type == .gameCenter {
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
                .listRowBackground(Color.white) 
                
            
            if config.playerMode == .twoPlayers {
                Section(header: Label("Select Second Player", systemImage: "person.2.fill")
                    .foregroundColor(AppTheme.primaryColor)) {
                        
                        // Dynamic list of available players
                        let available = di.playerRepo.playersSubject.value
                            .sorted { $0.lastUsed > $1.lastUsed }
                            .filter { $0.id != config.player1.id }
                        
                        ForEach(available, id: \.id) { player in
                            HStack {
                                Text(player.name)
                                Spacer()
                                if config.player2?.id == player.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                config.player2 = player
                            }
                        }
                        
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add New Player", systemImage: "plus.circle")
                                .foregroundColor(AppTheme.secondaryColor)
                        }
                    }
            }
        }
        .accentColor(AppTheme.primaryColor)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Setup Players")
        .sheet(isPresented: $showAddSheet) {
            AddPlayerView { newName in
                // 1. Create & save new player
                let newPlayer = Player(name: newName, type: .guest, lastUsed: Date())
                di.playerRepo.save(newPlayer)
                // 2. Set as Player 2 selection
                config.player2 = newPlayer
                showAddSheet = false
            }
        }
    }
}

private extension PlayerMode {
    @ViewBuilder
    var label: some View {
        switch self {
        case .singlePlayer:
            Label("Single Player", systemImage: "1.circle")
        case .twoPlayers:
            Label("Two Players", systemImage: "2.circle")
        case .againstComputer:
            Label {
                Text("VS Computer")
            } icon: {
                Image("robot.fill") // Ensure "robot" is the name of your asset
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
    }
}

