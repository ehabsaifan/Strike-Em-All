//
//  GameHeaderView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/9/25.
//

import SwiftUI

struct GameHeaderView: View {
    let player1: Player
    let player2: Player?
    let currentPlayer: Player
    let player1Score: Score
    let player2Score: Score?

    var onAction: (HeaderMenuAction) -> Void

    var player1StartingScore: Int {
        max(0, player1Score.total - player1Score.lastShotPointsEarned)
    }
    
    var player2StartingScore: Int {
        guard let s = player2Score else { return 0 }
        return max(0, s.total - s.lastShotPointsEarned)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    PlayerIndicatorView(isActive: currentPlayer == player1)
                    Text("\(player1.name):")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryColor)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: currentPlayer)
                    
                    AnimatedScoreView(startingScore: player1StartingScore,
                                      finalScore: player1Score.total)
                }
                
                if let player2 = player2, let player2Score = player2Score {
                    HStack(alignment: .center, spacing: 8) {
                        PlayerIndicatorView(isActive: currentPlayer == player2)
                        Text("\(player2.name):")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryColor)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: currentPlayer)
                        
                        AnimatedScoreView(startingScore: player2StartingScore,
                                          finalScore: player2Score.total)
                    }
                }
            }
            .padding(.leading, 16)
            
            Spacer()
            
            Menu {
                Button("Change Ball", action: { onAction(.changeBall) })
                Button("Volume", action: { onAction(.changeVolume) })
                Button("Quit Game", action: { onAction(.quit) })
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

struct PlayerIndicatorView: View {
    let isActive: Bool
    
    var body: some View {
        Group {
            if isActive {
                Circle()
                    .fill(Color.green)
            } else {
                Circle()
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
        .frame(width: 12, height: 12)
    }
}
