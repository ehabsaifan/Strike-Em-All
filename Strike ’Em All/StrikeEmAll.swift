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
    
    init() {
        SimpleDefaults.setEnum(LogLevel.info, forKey: .loggingLevel)
        SimpleDefaults.setValue(true, forKey: .loggingEnabled)
        FileLogger.shared.start(
            minLevel: SimpleDefaults.getEnum(forKey: .loggingLevel) ?? .debug,
            enabled: SimpleDefaults.getValue(forKey: .loggingEnabled) ?? false,
            metadata: LogFileHeader())
    }
    
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
    let cloud: CloudSyncServiceProtocol
    let playerRepo: PlayerRepositoryProtocol
    let gcReportService: GameCenterReportServiceProtocol
    let disk: Persistence
    let cloudCheckingService: CloudAvailabilityChecking
    
    private var analyticsCache: [Player: AnalyticsServiceProtocol] = [:]
    
    init() {
        let cloud = CloudSyncService()
        let disk = FileStorage()
        self.authService           = GameCenterService.shared
        self.gameCenter            = GameCenterService.shared
        self.disk                  = disk
        self.cloud                 = cloud
        self.playerRepo            = PlayerService(disk: disk, cloudSyncService: cloud)
        self.gcReportService       = GameCenterReportService(gcService: GameCenterService.shared)
        self.cloudCheckingService  = CloudAvailabilityService()
    }
    
    /// 3) Factory that reuses existing services
    lazy var analyticsFactory: (Player) -> AnalyticsServiceProtocol = { [unowned self] player in
        if let existing = analyticsCache[player] {
            return existing
        }
        let newService = AnalyticsService(
            disk: disk,
            player: player,
            cloud: cloud,
            availability: cloudCheckingService
        )
        analyticsCache[player] = newService
        return newService
    }
}

protocol DIContainer {
    var gameCenter: GameCenterProtocol { get }
    var authService: AuthenticationServiceProtocol { get }
    var playerRepo: PlayerRepositoryProtocol { get }
    var gcReportService: GameCenterReportServiceProtocol { get }
    var disk: Persistence { get }
    var cloud: CloudSyncServiceProtocol { get }
    var cloudCheckingService: CloudAvailabilityChecking { get }
    var analyticsFactory: (Player) -> AnalyticsServiceProtocol { get }
}
