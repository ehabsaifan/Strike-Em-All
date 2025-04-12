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
    private var physicsService: PhysicsServiceProtocol
    private var soundService: SoundServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var started = false
    
    @Published var rows: [GameRowProtocol] = []
    @Published var currentPlayer: Player
    @Published var winner: Player?
    @Published var player1: Player
    @Published var player2: Player
    @Published var gameMode: GameMode
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    @Published var rowFrames: [Int: CGRect] = [:]
    
    // Separate scores for each player:
    @Published var scorePlayer1: Score = Score()
    @Published var scorePlayer2: Score = Score()
    
    // Score managers for each player.
    var scoreManagerPlayer1: ScoreManagerProtocol
    var scoreManagerPlayer2: ScoreManagerProtocol?
    
    @Published var isWrapAroundEdgesEnabled = false {
        didSet {
            physicsService.setWrapAroundEnabled(isWrapAroundEdgesEnabled)
        }
    }
    
    // Other published properties...
    @Published var selectedBallType: RollingObjectType = .beachBall {
        didSet {
            gameService.setRollingObject(selectedBallType.rollingObject)
            updateRollingObject()
        }
    }
    
    @Published var volume: Float = 1.0 {
        didSet { soundService.setVolume(volume) }
    }
    
    let launchAreaVM: LaunchAreaViewModel
    let gameScene: GameScene
    let rowHeight: CGFloat = 70  // Used to calculate landing row
    
    static let ballDiameter: CGFloat = 40  // must match GameScene.ballSize
    static var ballStartYSpacing: CGFloat {
        launchAreaHeight + GameViewModel.bottomSafeAreaInset
    }
    static let launchAreaHeight: CGFloat = 100
    
    static var bottomSafeAreaInset: CGFloat {
        UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }
    static var screenWidth: CGFloat {
        UIApplication.shared.keyWindow?.frame.width ?? 0
    }
    
    var winnerFinalScore: Score {
        guard winner == player1 else {
            return scorePlayer2
        }
        return scorePlayer1
    }
    
    init(gameService: GameServiceProtocol,
         physicsService: PhysicsServiceProtocol,
         soundService: SoundServiceProtocol,
         gameScene: GameScene,
         gameMode: GameMode,
         player1: Player,
         player2: Player) {
        
        self.gameService = gameService
        self.physicsService = physicsService
        self.soundService = soundService
        self.gameScene = gameScene
        self.gameMode = gameMode
        self.player1 = player1
        self.currentPlayer = player1
        self.player2 = player2
        self.launchAreaVM = LaunchAreaViewModel(
            launchAreaHeight: GameViewModel.launchAreaHeight,
            ballDiameter: GameViewModel.ballDiameter
        )
        
        rows = []
        selectedBallType = gameService.rollingObject.type
        volume = soundService.volume
        
        self.scoreManagerPlayer1 = ScoreManager(calculator: ScoreCalculator())
        if gameMode != .singlePlayer {
            self.scoreManagerPlayer2 = ScoreManager(calculator: ScoreCalculator())
        }
        
        // Subscriptions for launch area updates…
        launchAreaVM.$dragOffset
            .sink { [weak self] newOffset in
                self?.updateBallPosition(with: newOffset)
            }
            .store(in: &cancellables)
        launchAreaVM.$launchImpulse
            .sink { [weak self] newImpulse in
                guard let newImpulse = newImpulse else { return }
                self?.launchBall(impulse: newImpulse)
            }
            .store(in: &cancellables)
        
        // Subscribe to both score managers.
        scoreManagerPlayer1.scorePublisher
            .sink { [weak self] score in
                self?.scorePlayer1 = score
            }
            .store(in: &cancellables)
        
        scoreManagerPlayer2?.scorePublisher
            .sink { [weak self] score in
                self?.scorePlayer2 = score
            }
            .store(in: &cancellables)
    }
    
    func startGame() {
        gameService.startGame(with: gameService.contentProvider.getSelectedContents())
        physicsService.setRollingObject(gameService.rollingObject)
        rows = gameService.rows
        scoreManagerPlayer1.gameStarted(player: player1.name)
        scoreManagerPlayer2?.gameStarted(player: player2.name)
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
        if started {
            playSound(.ropePull)
        }
        physicsService.updateBallPosition(with: offset)
        started = true
    }
    
    func launchBall(impulse: CGVector) {
        guard !isBallMoving else { return }
        isBallMoving = true
        stopSound(.ropePull)
        physicsService.moveBall(with: impulse, ball: gameService.rollingObject) { [weak self] finalPosition in
            guard let self = self else { return }
            gotFinalPostion(finalPosition)
        }
    }
    
    private func gotFinalPostion(_ finalPosition: CGPoint) {
        var success = false
        let player: GameService.PlayerType = (currentPlayer == player1) ? .player1 : .player2
        if let rowIndex = getRowAtBallPosition(finalPosition: finalPosition) {
            success = gameService.markCell(at: rowIndex, forPlayer: player)
            if player == .player1 {
                if success {
                    scoreManagerPlayer1.recordScore(atRow: rowIndex, player: player1.name)
                } else {
                    scoreManagerPlayer1.missedShot(player: player1.name)
                }
            } else {
                if success {
                    scoreManagerPlayer2?.recordScore(atRow: rowIndex, player: player2.name)
                } else {
                    scoreManagerPlayer2?.missedShot(player: player2.name)
                }
            }
            rows = gameService.rows
            physicsService.resetBall()
            
            switch gameService.checkForWinner() {
            case .player1:
                winner = player1
            case .player2:
                winner = player2
            case .none:
                break
            }
        } else {
            if player == .player1 {
                scoreManagerPlayer1.missedShot(player: player1.name)
            } else {
                scoreManagerPlayer2?.missedShot(player: player2.name)
            }
        }
        
        if winner == nil {
            playSound(success ? .hitStrike : .missStrike)
            toggleTurn()
        } else {
            playSound(.winner)
            if player == .player1 {
                scoreManagerPlayer1.gameEnded(player: player1.name, isAWinner: (player1 == winner)) { [weak self] finalScore in
                    self?.scorePlayer1 = finalScore
                }
            } else {
                scoreManagerPlayer2?.gameEnded(player: player2.name, isAWinner: (player2 == winner)) { [weak self] finalScore in
                    self?.scorePlayer2 = finalScore
                }
            }
        }
        isBallMoving = false
    }
    
    private func toggleTurn() {
        physicsService.resetBall()
        physicsService.setRollingObject(gameService.rollingObject)
        guard gameMode != .singlePlayer else {
            return
        }
        
        if gameMode == .againstComputer && currentPlayer != .computer {
            currentPlayer = .computer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.computerMove()
            }
        } else {
            currentPlayer = (currentPlayer == player1) ? player2 : player1
        }
    }
    
    func getContent(for index: Int) -> GameContent {
        return gameService.contentProvider.getContent(for: index)
    }
    
    func reset() {
        gameService.reset()
        physicsService.resetBall()
        rows = gameService.rows
        currentPlayer = player1
        winner = nil
        isBallMoving = false
        physicsService.setRollingObject(gameService.rollingObject)
        scoreManagerPlayer1.gameStarted(player: player1.name)
        scoreManagerPlayer2?.gameStarted(player: player2.name)
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
        soundService.playSound(for: event)
    }
    
    func stopSound(_ event: SoundEvent) {
        soundService.stopCurrentPlayingAudio()
    }
}
