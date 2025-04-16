//
//  GameCenterService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/6/25.
//

import GameKit

final class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()
    static let leaderboardID = "rollstrike.highscore"
    
    @Published var isAuthenticated = false
    
    static var player: GKLocalPlayer {
        GKLocalPlayer.local
    }
    
    // Use a completion block to indicate success or failure.
    func authenticateLocalPlayer(completion: @escaping (Bool, Error?) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let vc = viewController {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(vc, animated: true) {
                            completion(false, nil)
                        }
                    } else {
                        completion(false, error)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    print("Player authenticated: \(GKLocalPlayer.local.alias)")
                    completion(true, nil)
                } else {
                    self.isAuthenticated = false
                    completion(false, error)
                }
            }
        }
    }
    
    func reportScore(_ score: Int) {
        let scoreReporter = GKLeaderboardScore()
        scoreReporter.leaderboardID = GameCenterService.leaderboardID
        scoreReporter.value = score
        GKLeaderboard.submitScore(score,
                                  context: 0,
                                  player: GameCenterService.player,
                                  leaderboardIDs: [GameCenterService.leaderboardID]) { error in
            
            if let error = error {
                print("Error reporting score: \(error.localizedDescription)")
            } else {
                print("Score reported: \(score)")
            }
        }
    }
    
    func reportAchievement(achievment: GameCenterAchievment, percentComplete: Double) {
        let achievement = GKAchievement(identifier: achievment.rawValue)
        achievement.percentComplete = percentComplete
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement: \(error.localizedDescription)")
            } else {
                print("Achievement reported: \(achievment)")
            }
        }
    }
    
    func showLeaderboard() {
        let vc = GKGameCenterViewController(leaderboardID: GameCenterService.leaderboardID,
                                            playerScope: .global,
                                            timeScope: .allTime)
        vc.gameCenterDelegate = self
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
    func showAchievements() {
        let vc = GKGameCenterViewController()
        vc.gameCenterDelegate = self
        UIApplication.topViewController()?.present(vc, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterService: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
