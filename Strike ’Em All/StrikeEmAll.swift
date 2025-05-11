//
//  StrikeEmAll.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

@main
struct StrikeEmAll: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container = StrikeEmAllContainer()
    
    var body: some Scene {
        WindowGroup {
            LandingDashboardView(container: container)
        }
        .environment(\.di, container)
    }
}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = StrikeEmAllContainer()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

class StrikeEmAllContainer: DIContainer {
    let authService: AuthenticationServiceProtocol
    let gameCenter: GameCenterProtocol
    let playerRepo: PlayerRepositoryProtocol
    let gcReportService: GameCenterReportServiceProtocol
    let disk: Persistence
    let cloudCheckingService: CloudAvailabilityChecking
    
    private var analyticsCache: [String: AnalyticsServiceProtocol] = [:]
    
    init() {
        self.authService           = GameCenterService.shared
        self.gameCenter            = GameCenterService.shared
        self.playerRepo            = PlayerService.shared
        self.gcReportService       = GameCenterReportService(gcService: GameCenterService.shared)
        self.disk                  = FileStorage()
        self.cloudCheckingService  = CloudAvailabilityService()
    }
    
    /// 3) Factory that reuses existing services
    lazy var analyticsFactory: (String) -> AnalyticsServiceProtocol = { [unowned self] recordName in
        if let existing = analyticsCache[recordName] {
            return existing
        }
        let newService = AnalyticsService(
            disk: disk,
            cloud: CloudSyncService(recordName: recordName),
            availability: cloudCheckingService
        )
        analyticsCache[recordName] = newService
        return newService
    }
}

protocol DIContainer {
    var gameCenter: GameCenterProtocol { get }
    var authService: AuthenticationServiceProtocol { get }
    var playerRepo: PlayerRepositoryProtocol { get }
    var gcReportService: GameCenterReportServiceProtocol { get }
    var disk: Persistence { get }
    var cloudCheckingService: CloudAvailabilityChecking { get }
    var analyticsFactory: (String) -> AnalyticsServiceProtocol { get }
}
