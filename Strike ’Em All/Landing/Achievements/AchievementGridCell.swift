//
//  AchievementGridCell.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/8/25.
//

import SwiftUI

struct AchievementGridCell: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(achievement.badgeImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .saturation(achievement.isEarned ? 1 : 0)
                .opacity(achievement.isEarned ? 1 : 0.4)
                .cornerRadius(4)
            
            Text(achievement.isEarned
                 ? achievement.earnedDesc
                 : achievement.preEarnedDesc)
            .font(.caption)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(AppTheme.primaryColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
