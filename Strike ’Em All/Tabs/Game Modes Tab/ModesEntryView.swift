//
//  ModesEntryView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/25/25.
//

import SwiftUI

struct ModesEntryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.di) var di
    
    @State private var selectedMode: GameMode?
    @State private var config = GameConfiguration(player1: defaultPlayer1)
    
    // adaptive two-column grid
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    private var isDisabled: Bool {
        selectedMode == nil || appState.currentPlayer == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: — Player Header
                        if let player = appState.currentPlayer {
                            // MARK: — Player Card
                            Button {
                                appState.selectPlayer()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(AppTheme.secondaryColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(player.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Last played: \(player.lastUsed, style: .date)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Label("Change", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05),
                                                radius: 4, x: 0, y: 2)
                                )
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                Text("No player selected")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryColor)
                                Button("Select Player") {
                                    appState.selectPlayer()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.secondaryColor)
                            }
                            .padding(.vertical)
                            // early exit: don’t show grid or continue until we have a player
                            Spacer(minLength: 0)
                        }
                        
                        // MARK: — Mode Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(GameMode.allCases) { mode in
                                ModeCard(
                                    mode: mode,
                                    isSelected: mode == selectedMode
                                )
                                .onTapGesture {
                                    selectedMode = mode
                                    config.mode = mode
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    Spacer()
                    Button {
                        guard let _ = selectedMode else { return }
                        if let p1 = appState.currentPlayer {
                            config.player1 = p1
                        }
                        config.player2 = appState.currentConfig?.player2
                        appState.startGame(with: config)
                    } label: {
                        Text("Continue")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.secondaryColor.opacity(isDisabled ? 0.6: 1))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .shadow(color: Color.black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: -4)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(isDisabled)
                }
            }
            .navigationTitle("Choose Game Mode")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $appState.navigateToGameSettings) {
                GameSettingsView(config: $config)
                    .environment(\.di, di)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: — Mode “Card”
private struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: mode.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .foregroundColor(isSelected ? AppTheme.secondaryColor : .black)
                .clipped()
            
            Text(mode.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(mode.description)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(isSelected
                    ? AppTheme.secondaryColor.opacity(0.1)
                    : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected
                        ? AppTheme.secondaryColor
                        : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05),
                radius: 4, x: 0, y: 2)
    }
}
