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

  @StateObject private var statsVM: PlayerStatsViewModel
  @State private var isSigningInGC = false

    init(player: Player, di: DIContainer, onPlay: @escaping () -> Void) {
        let vm = PlayerStatsViewModel(player: player,
                                      analyticsFactory: di.analyticsFactory)
        _statsVM = StateObject(wrappedValue: vm)
        self.player = player
        self.onPlay = onPlay
    }

  var body: some View {
      VStack(spacing: 16) {
          Text("\(player.name)’s Stats")
              .font(.title2).bold()
          
          SingaleStatRow(label: "Games Played", value1: "\(statsVM.analytics.lifetimeGamesPlayed)")
          SingaleStatRow(label: "Total Score",   value1: "\(statsVM.analytics.lifetimeTotalScore)")
          SingaleStatRow(label: "Correct Shots", value1: "\(statsVM.analytics.lifetimeCorrectShots)")
          SingaleStatRow(label: "Missed Shots",  value1: "\(statsVM.analytics.lifetimeMissedShots)")
          SingaleStatRow(label: "Best Streak",   value1: "\(statsVM.analytics.lifetimeLongestWinningStreak)")
          
          Spacer()

      Group {
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
        }
      }

      Spacer()
    }
    .padding()
  }
}
