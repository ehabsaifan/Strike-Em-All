//
//  PlayerCardView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/27/25.
//

import SwiftUI

struct PlayerCardView: View {
  let title: String
  let player: Player?
  let placeholder: String
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Image(systemName: iconName)
          .resizable()
          .frame(width: 36, height: 36)
          .foregroundColor(AppTheme.secondaryColor)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
          Text(player?.name ?? placeholder)
            .font(.headline)
        }

        Spacer()

        Image(systemName: "arrow.triangle.2.circlepath")
          .foregroundColor(AppTheme.secondaryColor)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
      )
    }
    .buttonStyle(.plain)
  }

  private var iconName: String {
    guard let p = player else { return "person.crop.circle.badge.plus" }
    return p.type == .gameCenter
      ? "person.crop.circle.fill.badge.checkmark"
      : "person.crop.circle"
  }
}

// MARK: — ComputerCardView

struct ComputerCardView: View {
  var body: some View {
    HStack {
      Image(systemName: "desktopcomputer")
        .resizable().frame(width: 36, height: 36)
        .foregroundColor(.secondary)
      VStack(alignment: .leading, spacing: 2) {
        Text("Computer").font(.headline)
        Text("vs AI").font(.caption).foregroundColor(.secondary)
      }
      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    )
  }
}
