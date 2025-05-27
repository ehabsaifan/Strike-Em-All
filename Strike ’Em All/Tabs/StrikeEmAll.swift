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
    @StateObject private var appState = AppState()
    
    let container = StrikeEmAllContainer()
    
    init() {
        FileLogger.shared.start(
            minLevel: SimpleDefaults.getEnum(forKey: .loggingLevel) ?? .debug,
            enabled: SimpleDefaults.getValue(forKey: .loggingEnabled) ?? false,
            metadata: container.appMetaData)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.di, container)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.di)      var di
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            
            // — Players Tab —
            LandingDashboardView(container: di)
                .tabItem { Label("Players", systemImage: "person.3") }
                .tag(AppState.Tab.players)
                .environmentObject(appState)
            
            // — Modes Tab —
            ModesEntryView()
                .tabItem { Label("Modes", systemImage: "gamecontroller") }
                .tag(AppState.Tab.modes)
                .environmentObject(appState)
            
            // — Settings Tab —
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppState.Tab.settings)
                .environmentObject(appState)
        }
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
    let analyticsDisk: Persistence
    let cloudCheckingService: CloudAvailabilityChecking
    let appMetaData: AppMetadata
    
    private var analyticsCache: [Player: AnalyticsServiceProtocol] = [:]
    
    init() {
        let cloud = CloudSyncService()
        let analyticsDisk = FileStorage(subfolder: "Analytics")
        let playersDisk   = FileStorage(subfolder: "Players")
        self.authService           = GameCenterService.shared
        self.gameCenter            = GameCenterService.shared
        self.analyticsDisk         = analyticsDisk
        self.cloud                 = cloud
        self.playerRepo            = PlayerService(disk: playersDisk, cloudSyncService: cloud)
        self.gcReportService       = GameCenterReportService(gcService: GameCenterService.shared)
        self.cloudCheckingService  = CloudAvailabilityService()
        self.appMetaData = AppMetadata()
    }
    
    /// 3) Factory that reuses existing services
    lazy var analyticsFactory: (Player) -> AnalyticsServiceProtocol = { [unowned self] player in
        if let existing = analyticsCache[player] {
            return existing
        }
        let newService = AnalyticsService(
            disk: analyticsDisk,
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
    var analyticsDisk: Persistence { get }
    var cloud: CloudSyncServiceProtocol { get }
    var cloudCheckingService: CloudAvailabilityChecking { get }
    var analyticsFactory: (Player) -> AnalyticsServiceProtocol { get }
    var appMetaData: AppMetadata { get }
}
