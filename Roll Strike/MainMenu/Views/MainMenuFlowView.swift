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
    @State private var navigate = false
    
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
                }
                .disabled(config.playerMode == .twoPlayers && config.player2 == nil)
                .opacity((config.playerMode == .twoPlayers && config.player2 == nil) ? 0.5 : 1)
                .simultaneousGesture(TapGesture().onEnded {
                    if config.playerMode == .twoPlayers && config.player2 == nil {
                        showPlayerWarning = true
                      } else {
                        showPlayerWarning = false
                        navigate = true
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
            .padding()
            .onChange(of: config.player2, initial: false) { _,_ in
                showPlayerWarning = false
            }
            .onChange(of: config.playerMode, initial: false) { _, newVal in
                if newVal != .twoPlayers {
                    showPlayerWarning = false
                }
            }
            .navigationDestination(isPresented: $navigate) {
              GameSettingsView(config: $config)
                .environment(\.di, di)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
