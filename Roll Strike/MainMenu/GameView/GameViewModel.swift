//
//  GameViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    private let config: GameConfiguration
    private let gameService: GameServiceProtocol
    private let physicsService: PhysicsServiceProtocol
    private let soundService: SoundServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var started = false
    
    @Published var rows: [GameRowProtocol] = []
    @Published var currentPlayer: Player
    @Published var winner: Player? = nil
    @Published var player1: Player
    @Published var player2: Player
    @Published var playerMode: PlayerMode
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    @Published var rowFrames: [Int: CGRect] = [:]
    
    @Published var scorePlayer1: Score = Score()
    @Published var scorePlayer2: Score = Score()
    var scoreManagerPlayer1: ScoreServiceProtocol
    var scoreManagerPlayer2: ScoreServiceProtocol?
    
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
    
    init(
        config: GameConfiguration,
        gameService: GameServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        soundService: SoundServiceProtocol,
        gameScene: GameScene
    ) {
        self.config = config
        self.gameService = gameService
        self.physicsService = physicsService
        self.soundService = soundService
        self.gameScene = gameScene
        
        // Initialize from config
        self.playerMode = config.playerMode
        self.player1 = config.player1
        self.player2 = config.player2
        self.currentPlayer = config.player1
        self.isWrapAroundEdgesEnabled = config.wrapEnabled
        self.selectedBallType = config.rollingObjectType
        self.volume = config.volume
        
        // Score managers
        let analytics1 = AnalyticsService(recordName: config.player1.id)
        self.scoreManagerPlayer1 = ScoreService(calculator: ScoreCalculator(), analyticsService: analytics1)
        if config.playerMode != .singlePlayer {
            let analytics2 = AnalyticsService(recordName: config.player2.id)
            self.scoreManagerPlayer2 = ScoreService(calculator: ScoreCalculator(), analyticsService: analytics2)
        }
        
        // Launch area view model
        self.launchAreaVM = LaunchAreaViewModel(
            launchAreaHeight: GameViewModel.launchAreaHeight,
            ballDiameter: GameViewModel.ballDiameter
        )
        
        // Wire up Combine subscriptions
        setupBindings()
    }
    
    // MARK: –– Setup
    private func setupBindings() {
        launchAreaVM.$dragOffset
            .sink { [weak self] newOffset in
                self?.updateBallPosition(with: newOffset)
            }
            .store(in: &cancellables)
        
        launchAreaVM.$launchImpulse
            .compactMap { $0 }
            .sink { [weak self] impulse in
                self?.launchBall(impulse: impulse)
            }
            .store(in: &cancellables)
        
        scoreManagerPlayer1.scorePublisher
            .assign(to: &$scorePlayer1)
        
        scoreManagerPlayer2?
            .scorePublisher
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
        guard !isBallMoving else { return }
        physicsService.setRollingObject(gameService.rollingObject)
    }
    
    func updateBallPosition(with offset: CGSize) {
        guard !isBallMoving else { return }
        if started { playSound(.ropePull) }
        physicsService.updateBallPosition(with: offset)
        started = true
    }
    
    func launchBall(impulse: CGVector) {
        guard !isBallMoving else { return }
        isBallMoving = true
        stopSound(.ropePull)
        physicsService.moveBall(with: impulse, ball: gameService.rollingObject) { [weak self] finalPosition in
            self?.gotFinalPosition(finalPosition)
        }
    }
    
    private func gotFinalPosition(_ finalPosition: CGPoint) {
        var success = false
        let playerType: GameService.PlayerType = (currentPlayer == player1) ? .player1 : .player2
        if let rowIndex = getRowAtBallPosition(finalPosition: finalPosition) {
            success = gameService.markCell(at: rowIndex, forPlayer: playerType)
            if playerType == .player1 {
                if success { scoreManagerPlayer1.recordScore(atRow: rowIndex, player: player1.name) }
                else { scoreManagerPlayer1.missedShot(player: player1.name) }
            } else {
                if success { scoreManagerPlayer2?.recordScore(atRow: rowIndex, player: player2.name) }
                else { scoreManagerPlayer2?.missedShot(player: player2.name) }
            }
            rows = gameService.rows
            physicsService.resetBall()
            switch gameService.checkForWinner() {
            case .player1: winner = player1
            case .player2: winner = player2
            case .none: break
            }
        } else {
            if playerType == .player1 { scoreManagerPlayer1.missedShot(player: player1.name) }
            else { scoreManagerPlayer2?.missedShot(player: player2.name) }
        }
        if winner == nil {
            playSound(success ? .hitStrike : .missStrike)
            toggleTurn()
        } else {
            playSound(.winner)
            scoreManagerPlayer1.gameEnded(player: player1.name, isAWinner: (player1 == winner)) { [weak self] final in
                self?.scorePlayer1 = final
            }
            scoreManagerPlayer2?.gameEnded(player: player2.name, isAWinner: (player2 == winner)) { [weak self] final in
                self?.scorePlayer2 = final
            }
        }
        isBallMoving = false
    }
    
    private func getRowAtBallPosition(finalPosition: CGPoint) -> Int? {
        let sorted = rowFrames.sorted(by: { $0.key > $1.key })
        let ballCenterY = UIScreen.main.bounds.maxY - finalPosition.y
        for (index, frame) in sorted {
            if ballCenterY >= frame.minY && ballCenterY <= frame.maxY {
                return index
            }
        }
        return nil
    }
    
    private func toggleTurn() {
        physicsService.resetBall()
        physicsService.setRollingObject(gameService.rollingObject)
        guard playerMode != .singlePlayer else {
            return
        }
        
        if playerMode == .againstComputer && currentPlayer != computer {
            currentPlayer = computer
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
        guard currentPlayer == computer else { return }
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
