//
//  GameCenterService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/6/25.
//

import GameKit
import Combine

protocol AuthenticationServiceProtocol {
    var isAuthenticatedSubject: CurrentValueSubject<Bool, Never> { get }
    func authenticate(completion: @escaping (Bool, Error?) -> Void)
}

protocol GameCenterProtocol {
    var isAuthenticatedSubject: CurrentValueSubject<Bool, Never> { get }
    
    func report(_ val: Int, board: GameCenterLeaderBoardID)
    func reportAchievements(_ achievements: [GameCenterAchievment])
    func reportAchievement(achievment: GameCenterAchievment, percentComplete: Double)
    func showLeaderboard()
    func showAchievements()
}

final class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()
    let isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
    
    static var player: GKLocalPlayer {
        GKLocalPlayer.local
    }
}
 
// MARK: - AuthenticationServiceProtocol
extension GameCenterService: AuthenticationServiceProtocol {
    // Use a completion block to indicate success or failure.
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let error {
                    FileLogger.shared.log("Authentication error. \(error)", level: .error)
                }
                if let vc = viewController {
                    UIApplication.shared.rootVC?.present(vc, animated: true) {
                        completion(false, nil)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    FileLogger.shared.log("Authentication success", level: .debug)
                    self.isAuthenticatedSubject.send(true)
                    completion(true, nil)
                } else {
                    self.isAuthenticatedSubject.send(false)
                    completion(false, error)
                }
            }
        }
    }
}

// MARK: - GameCenterProtocol
extension GameCenterService: GameCenterProtocol {
    func report(_ val: Int, board: GameCenterLeaderBoardID) {
        
        let scoreReporter = GKLeaderboardScore()
        scoreReporter.leaderboardID = board.rawValue
        scoreReporter.value = val
        GKLeaderboard.submitScore(val,
                                  context: 0,
                                  player: GameCenterService.player,
                                  leaderboardIDs: [board.rawValue]) { error in
            
            if let error = error {
                FileLogger.shared.log("Error reporting \(val) to \(board.rawValue): \(error.localizedDescription)", level: .error)
            } else {
                FileLogger.shared.log("Report board \(board) with val \(val)", level: .debug)
            }
        }
    }
    
    func reportAchievement(achievment: GameCenterAchievment, percentComplete: Double = 100) {
        
        let achievement = GKAchievement(identifier: achievment.rawValue)
        achievement.percentComplete = percentComplete
        GKAchievement.report([achievement]) { error in
            if let error = error {
                FileLogger.shared.log("Error reporting achievement: \(error.localizedDescription)", level: .error)
            } else {
                FileLogger.shared.log("Report achievement \(achievment) with percentComplete \(percentComplete)", level: .debug)
            }
        }
    }
    
    func reportAchievements(_ achievements: [GameCenterAchievment]) {
        let gcAchievements: [GKAchievement] = achievements.map { ach in
            let gcAchievement = GKAchievement(identifier: ach.rawValue)
            gcAchievement.percentComplete = 100
            return gcAchievement
        }
        
        GKAchievement.report(gcAchievements) { error in
            if let error = error {
                FileLogger.shared.log("Error reporting achievements: \(error.localizedDescription)", level: .error)
            } else {
                FileLogger.shared.log("Report achievements \(gcAchievements) ", level: .debug)
            }
        }
    }
    
    func showLeaderboard() {
        let vc = GKGameCenterViewController(leaderboardID: GameCenterLeaderBoardID.score.rawValue,
                                            playerScope: .global,
                                            timeScope: .allTime)
        vc.gameCenterDelegate = self
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
    func showAchievements() {
        let vc = GKGameCenterViewController(state: .achievements)
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
