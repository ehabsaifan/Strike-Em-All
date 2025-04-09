//
//  GameHeaderView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/9/25.
//

import SwiftUI

struct GameHeaderView: View {
    let player1: Player
    let player2: Player?       // For multiplayer games; nil if not applicable.
    let currentPlayer: Player
    let player1Score: Int
    let player2Score: Int?     // If you have separate scores for player2.
    // Closure actions for the settings menu.
    var onChangeBall: () -> Void
    var onQuitGame: () -> Void

    var body: some View {
        HStack {
            // Left side: Player info with names and scores.
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(player1.name): ")
                        .font(.headline)
//                        .fontWeight(currentPlayer == player1 ? .bold : .regular)
                        .scaleEffect(currentPlayer == player1 ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: currentPlayer)
                    Text("\(player1Score)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryColor)
                }
                
                if let player2 = player2, let player2Score = player2Score {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(player2.name): ")
                            .font(.headline)
//                            .fontWeight(currentPlayer == player2 ? .bold : .regular)
                            .scaleEffect(currentPlayer == player2 ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: currentPlayer)
                        Text("\(player2Score)")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryColor)
                    }
                }
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // Right side: Settings menu
            Menu {
                Button("Change Ball", action: onChangeBall)
                Button("Quit Game", action: onQuitGame)
                // Additional menu options can be added here.
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.primaryColor)
                    .padding()
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
        .background(AppTheme.tertiaryColor.edgesIgnoringSafeArea(.horizontal))
    }
}
