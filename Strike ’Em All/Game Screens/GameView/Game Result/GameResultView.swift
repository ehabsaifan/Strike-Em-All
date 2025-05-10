//
//  GameResultView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 5/4/25.
//

import SwiftUI
import ConfettiSwiftUI

enum GameResultViewAction {
    case quit, restart
}

struct GameResultView: View {
    let result: GameResultInfo
    
    @State var onAction: ((GameResultViewAction) -> Void)?
    @State private var confettiCounter = 0
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                ResultStatsView(result: result)
                
                Spacer()
                
                VStack {
                    Button(action: {
                        onAction?(.restart)
                        onAction = nil
                    }) {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onAction?(.quit)
                        onAction = nil
                    }) {
                        Text("Quit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.secondaryColor)
                            .cornerRadius(8)
                    }
                }
            }
            .toolbar {
                // Share button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let image = ResultStatsView(result: result)
                            .padding()
                            .background(Color(.systemBackground))
                            .snapshot()
                        shareImage = image
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $shareImage) { image in
                ShareSheet(activityItems: [image])
            }
            .confettiCannon(trigger: $confettiCounter,
                            num: 300,
                            openingAngle: Angle(degrees: 0),
                            closingAngle: Angle(degrees: 360),
                            radius: 300)
            .onAppear {
                switch result.endState {
                case .lost:
                    break
                default:
                    confettiCounter += 1
                }
            }
        }
        .onDisappear {
            onAction?(.restart)
            onAction = nil
        }
        .padding([.leading, .trailing, .bottom])
        .navigationBarHidden(true)
    }
}

struct ResultStatsView: View {
    let result: GameResultInfo
    
    @State private var shareImage: UIImage?
    
    private var player1Accuracy: String {
        String(format: "%.0f%%", result.player1Accuracy * 100)
    }
    
    private var player2Accuracy: String? {
        guard let acc = result.player2Accuracy else { return nil }
        return String(format: "%.0f%%", acc * 100)
    }
    
    var body: some View {
        Text(titleText)
            .font(.largeTitle.bold())
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
        
        if let p2Info = result.player2Info {
            HStack(spacing: 30) {
                Text(result.player1Info.player.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(p2Info.player.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        
        Divider()
        
        if let player2Info = result.player2Info {
            CompStatRow(label: "Shots total",
                        value1: "\(result.player1Info.score.previousTotal)",
                        value2: "\(player2Info.score.previousTotal)")
            CompStatRow(label: "Winning bonus",
                        value1: "\(result.player1Info.score.winnerBonus)",
                        value2: "\(player2Info.score.winnerBonus)")
            CompStatRow(label: "Time bonus",
                        value1: "\(result.player1Info.score.timeBonus)",
                        value2: "\(player2Info.score.timeBonus)")
            CompStatRow(label: "Total score",
                        value1: "\(result.player1Info.score.total)",
                        value2: "\(player2Info.score.total)")
            
            CompStatRow(label: "Correct shots",
                        value1: result.player1Info.correctShotsDesc,
                        value2: player2Info.correctShotsDesc)
            CompStatRow(label: "Missed shots",
                        value1: result.player1Info.missedShotsDesc,
                        value2: player2Info.missedShotsDesc)
            CompStatRow(label: "Accuracy",
                        value1: player1Accuracy,
                        value2: player2Accuracy!)
        } else {
            SingleStatRow(label: "Shots total",
                          value: "\(result.player1Info.score.previousTotal)")
            SingleStatRow(label: "Winning bonus",
                          value: "\(result.player1Info.score.winnerBonus)")
            SingleStatRow(label: "Time bonus",
                          value: "\(result.player1Info.score.timeBonus)")
            SingleStatRow(label: "Total score",
                          value: "\(result.player1Info.score.total)")
            SingleStatRow(label: "Correct shots",
                          value: result.player1Info.correctShotsDesc)
            SingleStatRow(label: "Missed shots",
                          value: result.player1Info.missedShotsDesc)
            SingleStatRow(label: "Accuracy",
                          value: player1Accuracy)
        }
        
        Divider()
        HStack(spacing: 4) {
            Text("Time played:")
                .font(.caption)
                .foregroundStyle(AppTheme.accentColor)
            Text(result.timePlayed.formattedTime()).bold()
                .foregroundStyle(AppTheme.secondaryColor)
        }
    }
    
    private var titleText: String {
        switch result.endState {
        case .winner(let player): return "\(player.name)\nWins!"
        case .lost(let player):  return "\(player.name)\nLost!"
        case .tie:              return "It's a Tie!"
        }
    }
}
                
