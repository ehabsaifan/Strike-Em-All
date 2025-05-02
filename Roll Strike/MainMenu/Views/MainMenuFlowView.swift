//
//  MainMenuFlowView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/16/25.
//

import SwiftUI

struct MainMenuFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di
    
    @State private var config: GameConfiguration
    @State private var showPlayerWarning = false
    
    let loggedInPlayer: Player
    enum Route {
        case settings
    }
    
    init(loggedInPlayer: Player) {
        self.loggedInPlayer = loggedInPlayer
        _config = State(
            initialValue: GameConfiguration(player1: loggedInPlayer)
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                PlayerModeSelectionView(config: $config)
                    .environment(\.di, di)
                
                NavigationLink(value: Route.settings) {
                  Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(.white)
                    .background(AppTheme.primaryColor)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.25),
                                    radius: 4,
                                    x: 0,
                                    y: -4)
                }
                .padding()
                .disabled(config.playerMode == .twoPlayers && config.player2 == nil)
                .opacity((config.playerMode == .twoPlayers && config.player2 == nil) ? 0.5 : 1)
                .simultaneousGesture(TapGesture().onEnded {
                    if config.playerMode == .twoPlayers && config.player2 == nil {
                        showPlayerWarning = true
                      } else {
                        showPlayerWarning = false
                      }
                })
                
                if showPlayerWarning {
                    Text("⚠️ Please select a second player.")
                        .foregroundColor(AppTheme.warningColor)
                        .font(.subheadline)
                        .transition(.opacity)
                        .padding(.top, 4)
                }
            }
            .onChange(of: config.player2, initial: false) { _,_ in
                showPlayerWarning = false
            }
            .onChange(of: config.playerMode, initial: false) { _, newVal in
                if newVal != .twoPlayers {
                    showPlayerWarning = false
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                    case .settings:
                      GameSettingsView(config: $config)
                        .environment(\.di, di)
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
