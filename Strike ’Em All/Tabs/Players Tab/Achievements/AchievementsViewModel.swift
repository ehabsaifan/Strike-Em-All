//
//  AchievementsViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import SwiftUI
import Combine

class AchievementsViewModel: ObservableObject {
    @Published private var analytics: GameAnalytics = .init()
    
    let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
        analyticsService.analyticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.analytics = result
            }.store(in: &cancellables)
    }
    
    var achievements: (locked: [Achievement], unlocked: [Achievement]) {
        var achievedIDs = [String: Date]()
        for (index, val) in analytics.achievementEarnedIDs.enumerated() {
            achievedIDs[val] = index < analytics.achievementEarnedDates.count ? analytics.achievementEarnedDates[index] : Date()
        }
        
        var locked = [Achievement]()
        var unlocked = [Achievement]()
        for var ach in GameCenterAchievment.allAchievements() {
            if let date = achievedIDs[ach.id] {
                ach.dateEarned = date
                ach.isEarned = true
                unlocked.append(ach)
            } else {
                locked.append(ach)
            }
        }
        return (locked: locked, unlocked: unlocked)
    }
}
