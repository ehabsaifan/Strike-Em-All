//
//  AchievementDetailView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/8/25.
//

import SwiftUI

struct AchievementDetailView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 16) {
            Image(achievement.badgeImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .cornerRadius(8)
            
            Text(achievement.title)
                .font(.title2).bold()
            
            Text(achievement.isEarned
                 ? achievement.earnedDesc
                 : achievement.preEarnedDesc)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            
            if let date = achievement.dateEarned {
                Text("Earned on \(date, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 20)
        .padding()
    }
}
