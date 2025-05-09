//
//  PlayerStatsViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI
import Combine

class PlayerStatsViewModel: ObservableObject {
    @Published var analytics: GameAnalytics = .init()
    
    let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(player: Player, analyticsFactory: (String) -> AnalyticsServiceProtocol) {
        self.analyticsService = analyticsFactory(player.id)
        analyticsService.analyticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.analytics = result
            }.store(in: &cancellables)
        // subscribe to publisher
        analyticsService.loadAnalytics { _ in }
    }
}
