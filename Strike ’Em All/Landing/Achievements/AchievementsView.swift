//
//  AchievementsView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import SwiftUI

struct AchievementsView: View {
    @StateObject var viewModel: AchievementsViewModel
    @State private var selected: Achievement?
    
    // adaptive columns: as many 120pt cells as will fit
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    init(viewModel: AchievementsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    section(title: "Unlocked", items: viewModel.achievements.unlocked)
                    section(title: "Locked",   items: viewModel.achievements.locked)
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .sheet(item: $selected) { ach in
                AchievementDetailView(achievement: ach)
            }
        }
    }
    
    @ViewBuilder
    private func section(title: String, items: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2).bold()
                .padding(.horizontal, 4)
                .foregroundColor(AppTheme.primaryColor)
            
            if items.isEmpty {
                Text(title == "Unlocked"
                     ? "No achievements unlocked yet. Play to earn your first trophy!"
                     : "All achievements unlocked! 🎉")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryColor)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { ach in
                        AchievementGridCell(achievement: ach)
                            .onTapGesture { selected = ach }
                    }
                }
            }
        }
    }
}
