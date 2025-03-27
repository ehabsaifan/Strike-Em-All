//
//  GameViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

class GameViewModel: ObservableObject {
    private var gameService: GameServiceProtocol
    private var contentProvider: GameContentProvider
    private var physicsService: PhysicsServiceProtocol
    private var soundService: SoundServiceProtocol
        
    @Published var rows: [GameRowProtocol] = []
    @Published var currentPlayer: Player
    @Published var winner: Player?
    @Published var player1: Player
    @Published var player2: Player
    @Published var gameMode: GameMode
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    // For robust collision detection using screen coordinates (if desired)
    @Published var rowFrames: [Int: CGRect] = [:]
    
    let gameScene: GameScene
    let rowHeight: CGFloat = 70  // Used to calculate landing row
    
    static let ballDiameter: CGFloat = 40  // must match GameScene.ballSize
    static var ballStartYSpacing:CGFloat {
        launchAreaHeight + GameViewModel.bottomSafeAreaInset
    } // Must match gameScene.ballStartYSpacing
    static let launchAreaHeight: CGFloat = 100
    static var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
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
        rows = []
    }
    
    func startGame(with targets: [GameContent]) {
        gameService.startGame(with: targets)
        physicsService.setRollingObject(gameService.rollingObject)
        rows = gameService.rows
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
    
    // Temporarly for computer untill we simulate pulling in the launch view for computer
    private func rollBall() {
        print("@@ Now \(currentPlayer) is rolling the ball...")
        guard !isBallMoving else { return }
        isBallMoving = true
        //playSound(.ropeRelease)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playSound(.rolling)
        }
        let maxY = UIScreen.main.bounds.maxY
        physicsService.rollBallWithRandomPosition(maxY: maxY) { [weak self] finalPosition in
            guard let self = self else { return }
            gotFinalPostion(finalPosition)
        }
    }
    
    func launchBall() {
        print("@@ Now \(currentPlayer) is pushing the ball...")
        guard !isBallMoving else { return }
        guard let impulse = launchImpulse else { return }
        //playSound(.ropeRelease)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playSound(.rolling)
        }
        
        isBallMoving = true
        physicsService.moveBall(with: impulse, ball: gameService.rollingObject) { [weak self] finalPosition in
            guard let self = self else { return }
            gotFinalPostion(finalPosition)
        }
    }
    
    private func gotFinalPostion(_ finalPosition: CGPoint) {
        var success = false
        if let rowIndex = self.getRowAtBallPosition(finalPosition: finalPosition) {
            print("@@ Ball hit row: \(rowIndex)")
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
        }
        self.isBallMoving = false
    }

    private func toggleTurn() {
        physicsService.resetBall()
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
    
    private func computerMove() {
        guard currentPlayer == .computer else {
            return
        }
        rollBall()
    }

    func getContent(for index: Int) -> GameContent {
       // print("@@ returning \(contentProvider.getContent(for: index))")
        return contentProvider.getContent(for: index)
    }
    
    func reset() {
        print("@@ reset")
        gameService.reset()
        physicsService.resetBall()
        rows = gameService.rows
        currentPlayer = player1
        winner = nil
        isBallMoving = false
        physicsService.setRollingObject(gameService.rollingObject)
    }
}

// MARK: - Sound Service
extension GameViewModel {
    func playSound(_ event: SoundEvent) {
        soundService.playSound(for: event)
    }
}
