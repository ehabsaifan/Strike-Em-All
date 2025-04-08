//
//  GameViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    private var gameService: GameServiceProtocol
    private var contentProvider: GameContentProvider
    private var physicsService: PhysicsServiceProtocol
    private var soundService: SoundServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var rows: [GameRowProtocol] = []
    @Published var currentPlayer: Player
    @Published var winner: Player?
    @Published var player1: Player
    @Published var player2: Player
    @Published var gameMode: GameMode
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    @Published var rowFrames: [Int: CGRect] = [:]
    
    @Published var scoreManager: ScoreManagerProtocol = ScoreManager.shared
    
    @Published var isWrapAroundEdgesEnabled = false {
        didSet {
            physicsService.setWrapAroundEnabled(isWrapAroundEdgesEnabled)
        }
    }
    
    @Published var selectedBallType: RollingObjectType = .beachBall {
        didSet {
            gameService.setRollingObject(selectedBallType.rollingObject)
            updateRollingObject()
        }
    }
    
    let launchAreaVM: LaunchAreaViewModel
    let gameScene: GameScene
    let rowHeight: CGFloat = 70  // Used to calculate landing row
    
    static let ballDiameter: CGFloat = 40  // must match GameScene.ballSize
    static var ballStartYSpacing:CGFloat {
        launchAreaHeight + GameViewModel.bottomSafeAreaInset
    } // Must match gameScene.ballStartYSpacing
    static let launchAreaHeight: CGFloat = 100
    
    static var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }
    static var screenWidth: CGFloat {
        UIApplication.shared.keyWindow?.frame.width ?? 0
    }
        
    init(gameService: GameServiceProtocol,
         physicsService: PhysicsServiceProtocol,
         soundService: SoundServiceProtocol,
         contentProvider: GameContentProvider,
         gameScene: GameScene,
         gameMode: GameMode,
         player1: Player,
         player2: Player) {
        self.gameService = gameService
        self.physicsService = physicsService
        self.soundService = soundService
        self.contentProvider = contentProvider
        self.gameScene = gameScene
        self.gameMode = gameMode
        self.player1 = player1
        currentPlayer = player1
        self.player2 = player2
        self.launchAreaVM = LaunchAreaViewModel(
            launchAreaHeight: GameViewModel.launchAreaHeight,
            ballDiameter: GameViewModel.ballDiameter
        )
        
        rows = []
        selectedBallType = gameService.rollingObject.type
        
        launchAreaVM.$dragOffset
            .sink { [weak self] newOffset in
                self?.updateBallPosition(with: newOffset)
            }
            .store(in: &cancellables)
        
        launchAreaVM.$launchImpulse
            .sink { [weak self] newImpulse in
                guard let newImpulse else { return }
                self?.launchBall(impulse: newImpulse)
            }
            .store(in: &cancellables)
    }
    
    func startGame(with targets: [GameContent]) {
        gameService.startGame(with: targets)
        physicsService.setRollingObject(gameService.rollingObject)
        rows = gameService.rows
    }
    
    private func updateRollingObject() {
        guard !isBallMoving else {
            return
        }
        physicsService.setRollingObject(gameService.rollingObject)
    }
    
    private func enableWrapAroundEdges( _ enabled: Bool) {
        guard !isBallMoving else {
            return
        }
        isWrapAroundEdgesEnabled = enabled
    }
    
    // Robust, screen-based collision detection approach:
    // Here, we assume that the board's row frames have been captured via a PreferenceKey in the view.
    private func getRowAtBallPosition(finalPosition: CGPoint) -> Int? {
        let sortedRowFrames = rowFrames.sorted(by: { $0.key > $1.key }) // Ensure rows are in order
        
        let ballCenterY = UIScreen.main.bounds.maxY - finalPosition.y
        
        for (index, rowFrame) in sortedRowFrames {
            if (ballCenterY >= rowFrame.minY) && (ballCenterY <= rowFrame.maxY) {
                return index
            }
        }
        
        return nil
    }
    
    func updateBallPosition(with offset: CGSize) {
        guard !isBallMoving else { return }
        //playSound(.ropePull)
        physicsService.updateBallPosition(with: offset)
    }
    
    func launchBall(impulse: CGVector) {
        print("@@ Now \(currentPlayer) is pushing the ball...")
        guard !isBallMoving else { return }
        isBallMoving = true
        physicsService.moveBall(with: impulse, ball: gameService.rollingObject) { [weak self] finalPosition in
            guard let self = self else { return }
            gotFinalPostion(finalPosition)
        }
    }
    
    private func gotFinalPostion(_ finalPosition: CGPoint) {
        var success = false
        if let rowIndex = self.getRowAtBallPosition(finalPosition: finalPosition) {
            let player: GameService.PlayerType = self.currentPlayer == self.player1 ? .player1 : .player2
            success = self.gameService.markCell(at: rowIndex, forPlayer: player)
            self.rows = self.gameService.rows
            physicsService.resetBall()
            
            switch self.gameService.checkForWinner() {
            case .player1:
                self.winner = player1
            case .player2:
                self.winner = player2
            case .none:
                break
            }
        }
        
        if self.winner == nil {
            playSound(success ? .hitStrike : .missStrike)
            self.toggleTurn()
        } else {
            playSound(.winner)
            endGameAndSubmitScore()
        }
        self.isBallMoving = false
    }

    private func toggleTurn() {
        physicsService.resetBall()
        physicsService.setRollingObject(gameService.rollingObject)
        guard gameMode != .singlePlayer else {
            return
        }
        
        print("@@ Current Player now: \(currentPlayer.name)")
        if gameMode == .againstComputer && currentPlayer != .computer {
            currentPlayer = .computer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.computerMove()
            }
        } else {
            currentPlayer = (currentPlayer == player1) ? player2 : player1
            print("@@ Current Player now: \(currentPlayer.name)")
        }
    }
    
    func getContent(for index: Int) -> GameContent {
        return contentProvider.getContent(for: index)
    }
    
    func reset() {
        gameService.reset()
        physicsService.resetBall()
        rows = gameService.rows
        currentPlayer = player1
        winner = nil
        isBallMoving = false
        physicsService.setRollingObject(gameService.rollingObject)
    }
}

// MARK: - Computer move
extension GameViewModel {
    private func computerMove() {
        guard currentPlayer == .computer else { return }
        launchAreaVM.simulateComputerPull { [weak self] in
            guard let launchImpulse = self?.launchAreaVM.launchImpulse else { return }
            self?.launchBall(impulse: launchImpulse)
        }
    }
}

// MARK: - Sound Service
extension GameViewModel {
    func playSound(_ event: SoundEvent) {
        //soundService.playSound(for: event)
    }
}

extension GameViewModel {
    func endGameAndSubmitScore() {
        if currentPlayer == player1 {
            if scoreManager.player1Score != 0 {
                GameCenterManager.shared.reportAchievement(achievment: .firstWin,
                                                           percentComplete: 100)
            }
            scoreManager.updateScore(for: currentPlayer, by: 10)
            GameCenterManager.shared.reportScore(scoreManager.player1Score)
        }
    }
    
    func checkAchievements(for player: Player) {
//        let wins = player.totalWins
//
//        if wins >= 1 {
//            GameCenterManager.shared.unlockAchievement(identifier: "rollstrike.firstwin")
//        }
//        
//        if wins >= 5 {
//            GameCenterManager.shared.unlockAchievement(identifier: "rollstrike.fivewins")
//        }
//
//        if player.currentStreak >= 3 {
//            GameCenterManager.shared.unlockAchievement(identifier: "rollstrike.threestrikes")
//        }
    }
}
