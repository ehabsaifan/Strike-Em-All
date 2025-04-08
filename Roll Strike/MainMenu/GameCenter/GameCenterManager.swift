//
//  GameCenterManager.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/6/25.
//

import GameKit

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let leaderboardID = "rollstrike.highscore"
    
    @Published var isAuthenticated = false
    
    static var player: GKLocalPlayer {
        GKLocalPlayer.local
    }
    
    func authenticateLocalPlayer() {
        GameCenterManager.player.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Show login screen
                UIApplication.shared.keyWindow?.rootViewController?.present(viewController, animated: true)
            } else if GameCenterManager.player.isAuthenticated {
                self.isAuthenticated = true
                print("Player authenticated: \(GameCenterManager.player.alias)")
            } else {
                print("Game Center auth failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func reportScore(_ score: Int) {
        let scoreReporter = GKLeaderboardScore()
        scoreReporter.leaderboardID = GameCenterManager.leaderboardID
        scoreReporter.value = score
        GKLeaderboard.submitScore(score,
                                  context: 0,
                                  player: GameCenterManager.player,
                                  leaderboardIDs: [GameCenterManager.leaderboardID]) { error in
            if let error = error {
                print("Error reporting score: \(error.localizedDescription)")
            }
        }
    }
    
    func reportAchievement(achievment: GameCenterAchievment, percentComplete: Double) {
        let achievement = GKAchievement(identifier: achievment.rawValue)
        achievement.percentComplete = percentComplete
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement: \(error.localizedDescription)")
            }
        }
    }
    
    func showLeaderboard() {
        let vc = GKGameCenterViewController(leaderboardID: GameCenterManager.leaderboardID,
                                            playerScope: .global,
                                            timeScope: .allTime)
        vc.gameCenterDelegate = self
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.present(vc, animated: true, completion: nil)
        }
    }
    
    func showAchievements() {
        let vc = GKGameCenterViewController(achievementID: GameCenterAchievment.firstWin.rawValue)
        vc.gameCenterDelegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
