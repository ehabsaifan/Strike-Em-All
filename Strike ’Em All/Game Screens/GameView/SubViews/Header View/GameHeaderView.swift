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
                .padding(.leading, 0)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
                .scaleEffect(bouncing ? 1.2 : 1)
                .onChange(of: timeCounter, initial: false) { _, t in
                    guard enableBouncing else {
                        bouncing = false
                        return
                    }
                    if t > 0 && t <= 30 {
                        // Single bounce
                        withAnimation(.interpolatingSpring(stiffness: 500, damping: 20)) {
                            bouncing = true
                        }
                        // then immediately un-bounce after half a second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                bouncing = false
                            }
                        }
                    } else {
                        bouncing = false
                    }
                }
                .padding(.bottom, 4)
            VStack(alignment: .leading) {
                HStack {
                    if player2 != nil {
                        Text("\(currentPlayer.name)'s turn")
                            .font(.footnote.italic())
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.leading, 8)
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
                    .padding(.trailing, 8)
                }
                HStack {
                    HStack(alignment: .center, spacing: 8) {
                        Text("\(player1.name) →")
                            .font(isPlayer1Active ? .headline.bold() : .headline)
                            .foregroundColor(AppTheme.primaryColor)
                       
                        AnimatedScoreView(startingScore: player1Score.previousTotal,
                                          finalScore: player1Score.total)
                        
                        if player1Score.comboMultiplier > 1 {
                            ComboIndicator(combo: player1Score.comboMultiplier)
                        }
                    }
                    
                    if let player2 = player2, let player2Score = player2Score {
                        Spacer()
                        HStack(alignment: .center, spacing: 8) {
                            if player2Score.comboMultiplier > 1 {
                                ComboIndicator(combo: player2Score.comboMultiplier)
                            }
                           
                            AnimatedScoreView(startingScore: player2Score.previousTotal,
                                              finalScore: player2Score.total)
                            
                            Text("← \(player2.name)")
                                .font(!isPlayer1Active ? .headline.bold() : .headline)
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.bottom, 8)
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
