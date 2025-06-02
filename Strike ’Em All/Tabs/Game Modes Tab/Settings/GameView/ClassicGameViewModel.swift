//
//  ClassicGameViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import Combine
import SpriteKit

final class ClassicGameViewModel: ObservableObject, GameViewModelProtocol {
    @Published var player1: Player
    @Published var player2: Player?
    @Published var playerMode: PlayerMode
    @Published var currentPlayer: Player
    
    @Published var rows: [GameRowProtocol] = []
    @Published var rowFrames: [Int: CGRect] = [:]
    
    @Published var scorePlayer1: Score = Score()
    @Published var scorePlayer2: Score = Score()
    @Published var timeCounter: TimeInterval = 0
    @Published var result: GameResultInfo? = nil
    
    let launchAreaVM: LaunchAreaViewModel
    let gameScene: SKScene
    @Published var selectedBallType: RollingObjectType = .beachBall {
        didSet {
            updateRollingObject()
        }
    }
    @Published var volume: Float = 1.0 {
        didSet {
            soundService.setVolume(volume)
            SimpleDefaults.setValue(volume, forKey: .volumePref)
        }
    }
 
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    @Published var isWrapAroundEdgesEnabled = false {
        didSet {
            physicsService.setWrapAroundEnabled(isWrapAroundEdgesEnabled)
        }
    }
    
    var scoreManagerPlayer1: ScoreServiceProtocol
    var scoreManagerPlayer2: ScoreServiceProtocol?
    
    let config: GameConfiguration
    let gameService: GameServiceProtocol
    var physicsService: PhysicsServiceProtocol
    let soundService: SoundServiceProtocol
    let analyticsFactory: (Player) -> AnalyticsServiceProtocol
    let gcReportService: GameCenterReportServiceProtocol?
    let gameCenterService: GameCenterProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var started = false
    private(set) var endState: GameViewConstants.EndState? = nil
    
    init(
        config: GameConfiguration,
        gameService: GameServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        soundService: SoundServiceProtocol,
        analyticsFactory: @escaping (Player) -> AnalyticsServiceProtocol,
        gcReportService: GameCenterReportServiceProtocol?,
        gameCenterService: GameCenterProtocol?,
        gameScene: ClassicGameScene
    ) {
        self.config = config
        self.gameService = gameService
        self.physicsService = physicsService
        
        self.soundService = soundService
        self.analyticsFactory = analyticsFactory
        self.gameCenterService = gameCenterService
        self.gcReportService = gcReportService
        self.gameScene = gameScene
        
        self.playerMode = config.playerMode
        self.player1 = config.player1
        self.player2 = config.player2
        self.currentPlayer = config.player1
        self.isWrapAroundEdgesEnabled = config.wrapEnabled
        self.selectedBallType = config.rollingObjectType
        self.volume = config.volume
        
        var gcReportService1: GameCenterReportServiceProtocol?
        if config.player1.type == .gameCenter,
            gameCenterService?.isAuthenticatedSubject.value == true {
            gcReportService1 = gcReportService
        }
        
        let analytics1 = analyticsFactory(config.player1)
        self.scoreManagerPlayer1 = ScoreService(
            player: config.player1,
            calculator: config.isTimed ?
            TimedClassicScoreCalculator(totalTime: config.timeLimit) : ClassicScoreCalculator(),
            analyticsService: analytics1,
            gcReportService: gcReportService1)
        
        if config.playerMode != .singlePlayer,
           let secPlayer = config.player2 {
            var gcReportService2: GameCenterReportServiceProtocol?
            if secPlayer.type == .gameCenter,
                gameCenterService?.isAuthenticatedSubject.value == true {
                gcReportService2 = gcReportService
            }
            let analytics2 = analyticsFactory(secPlayer)
            self.scoreManagerPlayer2 = ScoreService(
                player: secPlayer,
                calculator: config.isTimed ?
                TimedClassicScoreCalculator(totalTime: config.timeLimit) : ClassicScoreCalculator(),
                analyticsService: analytics2,
                gcReportService: gcReportService2)
        }
        
        self.launchAreaVM = LaunchAreaViewModel(
            launchAreaHeight: GameViewConstants.launchAreaHeight,
            ballDiameter: GameViewConstants.ballDiameter
        )
        
        self.physicsService.delegate = self
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
    
    private func updateRollingObject() {
        gameService.setRollingObject(selectedBallType.rollingObject)
        physicsService.setRollingObject(gameService.rollingObject)
    }
    
    private func gotFinalPosition(_ finalPosition: CGPoint) {
        var success = false
        var winner: Player?
        let playerType: GameService.PlayerType = (currentPlayer == player1) ? .player1 : .player2
        
        if let rowIndex = getRowAtBallPosition(finalPosition: finalPosition) {
            success = gameService.markCell(at: rowIndex, forPlayer: playerType)
            if playerType == .player1 {
                if success { scoreManagerPlayer1.recordScore(atRow: rowIndex) }
                else { scoreManagerPlayer1.missedShot() }
            } else {
                if success { scoreManagerPlayer2?.recordScore(atRow: rowIndex) }
                else { scoreManagerPlayer2?.missedShot() }
            }
            rows = gameService.rows
            physicsService.restart()
            switch gameService.playerCompletedGame() {
            case .player1:
                winner = player1
                endState = .winner(player1)
            case .player2:
                winner = player2
                endState = .winner(player2!)
            case .none: break
            }
        } else {
            if playerType == .player1 { scoreManagerPlayer1.missedShot() }
            else { scoreManagerPlayer2?.missedShot() }
        }
        if endState == nil {
            playSound(success ? .hitStrike : .missStrike)
            toggleTurn()
        } else {
            reportSores(winner: winner)
        }
        isBallMoving = false
    }
    
    private func endGameDueToTimeout() {
        var winner: Player?
        switch config.playerMode {
        case .singlePlayer:
            endState = .lost(player1)
        default:
            if scorePlayer1.total != scorePlayer2.total {
                winner = scorePlayer1.total > scorePlayer2.total ? player1: player2
                endState = .winner(winner!)
            } else {
                let player1Rows = gameService.getRowsStatus(for: .player1)
                let player2Rows = gameService.getRowsStatus(for: .player2)
                if player1Rows.correctShots != player2Rows.correctShots {
                    winner = player1Rows.correctShots > player2Rows.correctShots ? player1: player2
                    endState = .winner(winner!)
                } else if player1Rows.completedRows != player2Rows.completedRows {
                    winner = player1Rows.completedRows > player2Rows.completedRows ? player1: player2
                    endState = .winner(winner!)
                }
            }
        }
        if endState == nil {
            endState = .tie
        }
        reportSores(winner: winner)
    }
    
    private func reportSores(winner: Player?) {
        switch endState {
        case .lost:
            //Play loosing sound playSound(.winner)
            break
        case .tie,
                .winner:
            playSound(.winner)
        default:
            break
        }
        scoreManagerPlayer1.gameEnded(isAWinner: (player1 == winner)) { [weak self] final in
            self?.scorePlayer1 = final
        }
        scoreManagerPlayer2?.gameEnded(isAWinner: (player2! == winner)) { [weak self] final in
            self?.scorePlayer2 = final
        }
        prepareResultInfo()
        resetBall()
        timerCancellable?.cancel()
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
        physicsService.restart()
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
            currentPlayer = (currentPlayer == player1) ? player2! : player1
        }
    }
    
    private func startTimer() {
        timeCounter = config.timeLimit
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                switch config.timeMode {
                case .unlimited:
                    timeCounter += 1
                case .limited:
                    timeCounter -= 1
                    if timeCounter <= 0 {
                        timerCancellable?.cancel()
                        endGameDueToTimeout()
                    }
                }
            }
    }
    
    private func prepareResultInfo() {
        let analy = scoreManagerPlayer1.analyticsService.analyticsPublisher.value
        let player1Info = PlayerResultInfo(player: player1,
                                           score: scorePlayer1,
                                           correctShots: analy.lastGameCorrectShots,
                                           missedShots: analy.lastGameMissedShots)
        var player2Info: PlayerResultInfo?
        if let analy2 = scoreManagerPlayer2?.analyticsService.analyticsPublisher.value {
            player2Info = PlayerResultInfo(player: player2!,
                                           score: scorePlayer2,
                                           correctShots: analy2.lastGameCorrectShots,
                                           missedShots: analy2.lastGameMissedShots)
        }
        
        self.result = GameResultInfo(endState: endState!,
                                     timePlayed: scoreManagerPlayer1.gameTimePlayed!,
                                     player1Info: player1Info,
                                     player2Info: player2Info)
    }
    
    private func resetBall() {
        physicsService.restart()
        isBallMoving = false
    }
}

// MARK: - Public methods
extension ClassicGameViewModel {
    func restartGame() {
        gameService.reset()
        resetBall()
        currentPlayer = player1
        endState = nil
        
        rows = gameService.rows
        physicsService.setRollingObject(gameService.rollingObject)
        scoreManagerPlayer1.gameStarted()
        scoreManagerPlayer2?.gameStarted()
        result = nil
        timerCancellable?.cancel()
        startTimer()
    }
    
    func startGame() {
        gameService.startGame(with: gameService.contentProvider.getSelectedContents())
        rows = gameService.rows
        physicsService.setRollingObject(gameService.rollingObject)
        scoreManagerPlayer1.gameStarted()
        scoreManagerPlayer2?.gameStarted()
        startTimer()
    }
    
    func updateBallPosition(with offset: CGSize) {
        guard !isBallMoving else { return }
        if started { playSound(.ropePull) }
        physicsService.playerPulledBall(with: offset)
        started = true
    }
    
    func launchBall(impulse: CGVector) {
        guard !isBallMoving else { return }
        isBallMoving = true
        stopSound(.ropePull)
        physicsService.apply(impulse)
    }
}

extension ClassicGameViewModel: PhysicsServiceDelegate {
    func allBallsCameToRest() {
        // No Need to do anything as its only one ball at a time!
    }
    
    func created(_ ball: Ball) {
        FileLogger.shared.log("Created ball", object: ball, level: .debug)
        //print("\(ball.name) created")
    }
    
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint) {
        //print("\(ball.name) stopped at \(position)")
        gotFinalPosition(position)
        FileLogger.shared.log("Ball stopped at \(position)", object: ball, level: .verbose)
    }
}
