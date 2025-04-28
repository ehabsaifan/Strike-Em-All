//
//  RollStrikeApp.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

@main
struct RollStrikeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
    let container = RollStrikeContainer()
    
    var body: some Scene {
        WindowGroup {
            LandingDashboardView(container: container)
        }
        .environment(\.di, container)
    }
}

private struct DIContainerKey: EnvironmentKey {
  static let defaultValue: DIContainer = RollStrikeContainer()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

struct RollStrikeContainer: DIContainer {
    let authService: AuthenticationServiceProtocol = GameCenterService.shared
    let gameCenter: GameCenterProtocol   = GameCenterService.shared
    let playerRepo: PlayerRepositoryProtocol = PlayerService.shared
    let achievementService: AchievementServiceProtocol = AchievementService.shared
    
    // **Instead** of a single AnalyticsService, expose a factory:
    let analyticsFactory: (String) -> AnalyticsServiceProtocol = { recordName in
        AnalyticsService(recordName: recordName)
    }
}

protocol DIContainer {
    var gameCenter: GameCenterProtocol { get }
    var authService: AuthenticationServiceProtocol { get }
    var playerRepo: PlayerRepositoryProtocol { get }
    var achievementService: AchievementServiceProtocol { get }
    
    /// NEW: factory to create per‐player analytics
    var analyticsFactory: (String) -> AnalyticsServiceProtocol { get }
}
