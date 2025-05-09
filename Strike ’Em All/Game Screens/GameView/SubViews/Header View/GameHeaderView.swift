//
//  GameHeaderView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/9/25.
//

import SwiftUI

struct GameHeaderView: View {
    @State private var bouncing = false
    
    let player1: Player
    let player2: Player?
    let currentPlayer: Player
    let player1Score: Score
    let player2Score: Score?
    let timeCounter: TimeInterval
    let enableBouncing: Bool
    
    var onAction: (HeaderMenuAction) -> Void

    private var isPlayer1Active: Bool {
        currentPlayer == player1
    }
    
    var body: some View {
        ZStack {
            Text(timeCounter.formattedTime())
                .padding(.leading, 16)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
                .scaleEffect(bouncing ? 1.2 : 1)
                .onChange(of: timeCounter, initial: false) { _, t in
                    if enableBouncing, t <= 30 {
                        withAnimation(.interpolatingSpring(stiffness: 500, damping: 20)
                            .repeatForever(autoreverses: true)) {
                                bouncing = true
                            }
                    }
                }
            VStack(alignment: .leading) {
                HStack {
                    if player2 != nil {
                        Text("\(currentPlayer.name)'s turn")
                            .font(.headline.italic())
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.leading, 16)
                    }
                    Spacer()
                    Menu {
                        Button("Change Ball", action: { onAction(.changeBall) })
                        Button("Volume", action: { onAction(.changeVolume) })
                        Button("Quit Game", action: { onAction(.quit) })
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(AppTheme.primaryColor)
                    }
                    .padding(.trailing, 16)
                }
                HStack {
                    HStack(alignment: .center, spacing: 8) {
                        Text("\(player1.name) →")
                            .font(isPlayer1Active ? .headline.bold() : .headline)
                            .foregroundColor(AppTheme.primaryColor)
                        
                        // your existing score view
                        AnimatedScoreView(startingScore: player1Score.previousTotal,
                                          finalScore: player1Score.total)
                        
                        // new combo badge
                        if player1Score.comboMultiplier > 1 {
                            ComboIndicator(combo: player1Score.comboMultiplier)
                        }
                    }
                    
                    if let player2 = player2, let player2Score = player2Score {
                        Spacer()
                        HStack(alignment: .center, spacing: 8) {
                            AnimatedScoreView(startingScore: player2Score.previousTotal,
                                              finalScore: player2Score.total)
                            
                            // combo badge for player2
                            if player2Score.comboMultiplier > 1 {
                                ComboIndicator(combo: player2Score.comboMultiplier)
                            }
                            
                            Text("← \(player2.name)")
                                .font(!isPlayer1Active ? .headline.bold() : .headline)
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(.bottom)
    }
}

struct ComboIndicator: View {
    let combo: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text("+ \(combo)")
                .font(.caption2.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}
