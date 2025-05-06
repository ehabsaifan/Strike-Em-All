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
                if let vc = viewController {
                    UIApplication.shared.rootVC?.present(vc, animated: true) {
                        completion(false, nil)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
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
                print("Error reporting \(val) to \(board.rawValue): \(error.localizedDescription)")
            } else {
                print("Reported: \(val) to \(board.rawValue)")
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
