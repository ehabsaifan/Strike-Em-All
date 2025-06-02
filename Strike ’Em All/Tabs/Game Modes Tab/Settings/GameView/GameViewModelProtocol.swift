//
//  GameViewModelProtocol.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/28/25.
//

import Foundation
import SpriteKit

protocol GameViewModelProtocol: ObservableObject {
    // Services
    var config: GameConfiguration { get }
    var gameService: GameServiceProtocol { get }
    var physicsService: PhysicsServiceProtocol { get }
    var soundService: SoundServiceProtocol { get }
    var analyticsFactory: (Player) -> AnalyticsServiceProtocol { get }
    var gcReportService: GameCenterReportServiceProtocol? { get }
    var gameCenterService: GameCenterProtocol? { get }
    
    // Players
    var player1: Player { get }
    var player2: Player? { get }
    var playerMode: PlayerMode { get }
    var currentPlayer: Player { get }
    
    // Board state
    var rows: [GameRowProtocol] { get }
    var rowFrames: [Int: CGRect] { get set }
    var rowHeight: CGFloat { get }
    
    // Scoring & timing
    var scorePlayer1: Score { get }
    var scorePlayer2: Score { get }
    var timeCounter: TimeInterval { get }
    var result: GameResultInfo? { get set }
    var isTimed: Bool { get }
    
    // Overlays
    var launchAreaVM: LaunchAreaViewModel { get }
    var gameScene: SKScene { get }
    var selectedBallType: RollingObjectType { get set }
    var volume: Float { get set }
    
    // Others
    var isBallMoving: Bool { get }
    var launchImpulse: CGVector? { get }
    var isWrapAroundEdgesEnabled: Bool { get }
    var scoreManagerPlayer1: ScoreServiceProtocol { get }
    var scoreManagerPlayer2: ScoreServiceProtocol? { get }
    var winnerFinalScore: Score { get }
    var endState: GameViewConstants.EndState? { get }
    
    // Actions
    func startGame()
    func restartGame()
    func updateBallPosition(with offset: CGSize)
    func launchBall(impulse: CGVector)
    func getContent(for index: Int) -> GameContent
    func playSound(_ event: SoundEvent)
    func stopSound(_ event: SoundEvent)
    func computerMove()
}

extension GameViewModelProtocol {
    var launchAreaVM: LaunchAreaViewModel {
        LaunchAreaViewModel(
            launchAreaHeight: GameViewConstants.launchAreaHeight,
            ballDiameter: GameViewConstants.ballDiameter
        )
    }
    
    var rowHeight: CGFloat {
        GameViewConstants.rowHeight
    }
    
    var isTimed: Bool {
        config.isTimed
    }
    
    var winnerFinalScore: Score {
        guard let endState = endState else {
            fatalError("invalid end state")
        }
        switch endState {
        case .tie:
            return scorePlayer1
        case .lost:
            return scorePlayer1
        case .winner(let player):
            if player == player2 {
                return scorePlayer2
            }
            return scorePlayer1
        }
    }

    func playSound(_ event: SoundEvent) {
        soundService.playSound(for: event)
    }
    
    func stopSound(_ event: SoundEvent) {
        soundService.stopCurrentPlayingAudio()
    }
    
    func getContent(for index: Int) -> GameContent {
        return gameService.contentProvider.getContent(for: index)
    }
    
    func computerMove() {
        guard currentPlayer == computer else { return }
        launchAreaVM.simulateComputerPull { [weak self] in
            guard let launchImpulse = self?.launchAreaVM.launchImpulse else { return }
            self?.launchBall(impulse: launchImpulse)
        }
    }
}

struct GameViewConstants {
    static let rowHeight: CGFloat = 70
    static let ballDiameter: CGFloat = 40  // must match GameScene.ballSize
    static let launchAreaHeight: CGFloat = 100
    
    static var ballStartYSpacing: CGFloat {
        launchAreaHeight + bottomSafeAreaInset
    }
    
    static var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }
    static var screenWidth: CGFloat {
        UIApplication.shared.keyWindow?.frame.width ?? 0
    }
    
    enum EndState: Codable, Equatable {
        case tie, lost(Player), winner(Player)
    }
}
