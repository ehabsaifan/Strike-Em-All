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
    
    let gameCenterService = GameCenterService.shared
    let playerRepo     = PlayerService.shared
    let container      = RollStrikeContainer(gameCenterService: GameCenterService.shared,
                                             authService: GameCenterService.shared,
                                             playerRepo: PlayerService.shared)
    
    var body: some Scene {
        WindowGroup {
            LandingView(container: container)
        }
        .environmentObject(playerRepo)
        .environmentObject(gameCenterService)
    }
}

struct RollStrikeContainer: DIContainer {
    var gameCenterService: any GameCenterProtocol
    var authService: any AuthenticationServiceProtocol
    var playerRepo: any PlayerRepositoryProtocol
    
    
}
protocol DIContainer {
    var gameCenterService: GameCenterProtocol { get }
    var authService: AuthenticationServiceProtocol { get }
    var playerRepo: PlayerRepositoryProtocol { get }
}
