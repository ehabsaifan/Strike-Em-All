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
    
    private var player1Accuracy: String {
        String(format: "%.0f%%", result.player1Accuracy * 100)
    }
    
    private var player2Accuracy: String? {
        guard let acc = result.player2Accuracy else { return nil }
        return String(format: "%.0f%%", acc * 100)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // MARK: –– Title
                Text(titleText)
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .padding(.vertical)
                
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
                    CompStatRow(label: "Score",
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
                    SingaleStatRow(label: "Score",
                                   value1: "\(result.player1Info.score.total)")
                    SingaleStatRow(label: "Correct shots",
                                   value1: result.player1Info.correctShotsDesc)
                    SingaleStatRow(label: "Missed shots",
                                   value1: result.player1Info.missedShotsDesc)
                    SingaleStatRow(label: "Accuracy",
                                   value1: player1Accuracy)
                }
                
                Divider()
                HStack(spacing: 4) {
                    Text("Time played:")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentColor)
                    Text(result.timePlayed.formattedTime).bold()
                        .foregroundStyle(AppTheme.secondaryColor)
                }
                //.frame(maxWidth: .infinity, alignment: .leading)
                
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
        .padding()
        .navigationBarHidden(true)
    }
    
    private var titleText: String {
        switch result.endState {
        case .winner(let player): return "\(player.name) Wins!"
        case .lost(let player):  return "\(player.name) Lost!"
        case .tie:              return "It's a Tie!"
        }
    }
}

struct SingaleStatRow: View {
    let label: String, value1: String
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.accentColor)
            Spacer()
            Text(value1).bold()
                .foregroundStyle(AppTheme.secondaryColor)
        }
    }
}

struct CompStatRow: View {
    let label: String, value1: String, value2: String
    var body: some View {
        HStack {
            Text(value1).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(AppTheme.secondaryColor)
                .padding(.leading)
                .multilineTextAlignment(.center)
            Spacer()
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            Spacer()
            Text(value2).bold()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(AppTheme.secondaryColor)
                .padding(.trailing)
                .multilineTextAlignment(.center)
        }
    }
}
