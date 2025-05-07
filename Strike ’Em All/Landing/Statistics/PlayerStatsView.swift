//
//  PlayerStatsView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI

struct PlayerStatsView: View {
    @Environment(\.di) private var di
    let player: Player
    let onPlay: () -> Void
    
    @StateObject private var viewModel: PlayerStatsViewModel
    @State private var isSigningInGC = false
    @State private var shareImage: UIImage?
    
    init(player: Player, di: DIContainer, onPlay: @escaping () -> Void) {
        let vm = PlayerStatsViewModel(player: player,
                                      analyticsFactory: di.analyticsFactory)
        _viewModel = StateObject(wrappedValue: vm)
        self.player = player
        self.onPlay = onPlay
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    StatsContentView(playerName: player.name,
                                     analytics: viewModel.analytics)
                    
                    Spacer()
                    
                    if player.type == .gameCenter && !di.authService.isAuthenticatedSubject.value {
                        Button(action: {
                            isSigningInGC = true
                            di.authService.authenticate { success, _ in
                              DispatchQueue.main.async {
                                isSigningInGC = false
                                if success {
                                  onPlay()
                                }
                              }
                            }
                        }) {
                            HStack {
                                if isSigningInGC {
                                    ProgressView()
                                }
                                Text("Sign in to Game Center")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.secondaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding()
                    } else {
                        Button(action: {
                            onPlay()
                        }) {
                            Text("▶︎ Play Now")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            let image = StatsContentView(playerName: player.name,
                                                         analytics: viewModel.analytics)
                                .padding()
                                .background(Color(.systemBackground))
                                .snapshot()
                            shareImage = image
                        }
                        label: { Image(systemName: "square.and.arrow.up") }
                    }
                }
                .sheet(item: $shareImage) { image in
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }
}

struct StatsContentView: View {
    let playerName: String
    let analytics: GameAnalytics  // your model
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(playerName)’s\nStrike ’Em All Stats")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            Divider()
            
            HStack(spacing: 4) {
                Text("Total Time")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentColor)
                Text(analytics.lifetimeTotalTimePlayed.formattedTime(alwaysShowHours: true)).bold()
                    .foregroundStyle(AppTheme.secondaryColor)
            }
            Divider()
            Group {
                SingleStatRow(label: "Games Played",
                              value: "\(analytics.lifetimeGamesPlayed)")
                SingleStatRow(label: "Total Wins",
                              value: "\(analytics.lifetimeWinnings)")
                SingleStatRow(label: "Total Lost",
                              value: "\(analytics.totalLost)")
                SingleStatRow(label: "Best Winning Streak",
                              value: "\(analytics.lifetimeLongestWinningStreak)")
                SingleStatRow(label: "Total Score",
                              value: "\(analytics.lifetimeTotalScore)")
                
                SingleStatRow(label: "Perfect Games",
                              value: "\(analytics.lifetimePerfectGamesCount)")
                SingleStatRow(label: "Longest Perfect-Game Streak",
                              value: "\(analytics.lifetimeLongestPerfectGamesStreak)")
                
                SingleStatRow(label: "Correct Shots",
                              value: "\(analytics.lifetimeCorrectShots)")
                SingleStatRow(label: "Missed Shots",
                              value: "\(analytics.lifetimeMissedShots)")
                SingleStatRow(label: "Overall Accuracy",
                              value: "\(analytics.overAllAccuracy)")
            }
        }
        .padding([.leading, .trailing, .bottom])
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }
}
