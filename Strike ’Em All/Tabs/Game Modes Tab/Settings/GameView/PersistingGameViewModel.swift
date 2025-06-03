//
//  PersistingGameViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/28/25.
//

import SwiftUI
import Combine
import SpriteKit

final class PersistingGameViewModel: ObservableObject, GameViewModelProtocol {
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
    @Published var ballsLeft: [Player:Int]
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
    
    
    private var player1BallsSet = Set<Ball>()
    private var player2BallsSet = Set<Ball>()
    private var player1BallsPositionDict = [Ball: CGPoint]()
    private var player2BallsPositionDict = [Ball: CGPoint]()
    
    private(set) var endState: GameViewConstants.EndState? = nil
    
    var player1BallsLeft: Int {
        ballsLeft[player1] ?? 0
    }

    var player2BallsLeft: Int {
        guard let p2 = player2 else { return 0 }
        return ballsLeft[p2] ?? 0
    }

    init(
        config: GameConfiguration,
        gameService: GameServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        soundService: SoundServiceProtocol,
        analyticsFactory: @escaping (Player) -> AnalyticsServiceProtocol,
        gcReportService: GameCenterReportServiceProtocol?,
        gameCenterService: GameCenterProtocol?,
        gameScene: PersistingGameScene
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
            calculator: PersistingClassicScoreCalculator(),
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
                calculator: PersistingClassicScoreCalculator(),
                analyticsService: analytics2,
                gcReportService: gcReportService2)
        }

        self.launchAreaVM = LaunchAreaViewModel(
          launchAreaHeight: GameViewConstants.launchAreaHeight,
          ballDiameter: GameViewConstants.ballDiameter)

        // set up remaining‐balls
        var countDict = [config.player1: config.ballsPerPlayer]
        if let p2 = config.player2 { countDict[p2] = config.ballsPerPlayer }
        self.ballsLeft = countDict
        self.physicsService.delegate = self
        
        self.physicsService.enableBallsBorder(player2 != nil)
        // touch/drags
        setupBindings()
    }

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
    
    private func calculatePositions() {
        // Row index : strikes count
        var player1CurrentResult = [Int: Int]()
        // Row index : strikes count
        var player2CurrentResult = [Int: Int]()
        gameService.reset()
        for position in player1BallsPositionDict.values {
            if let rowIndex = getRowAtBallPosition(finalPosition: position) {
                _ = gameService.markCell(at: rowIndex, forPlayer: .player1)
                if let count = player1CurrentResult[rowIndex] {
                    player1CurrentResult[rowIndex] = count + 1
                } else {
                    player1CurrentResult[rowIndex] = 1
                }
            }
        }
            
        for position in player2BallsPositionDict.values {
            if let rowIndex = getRowAtBallPosition(finalPosition: position) {
                _ = gameService.markCell(at: rowIndex, forPlayer: .player2)
                if let count = player2CurrentResult[rowIndex] {
                    player2CurrentResult[rowIndex] = count + 1
                } else {
                    player2CurrentResult[rowIndex] = 1
                }
            }
        }
        
        rows = gameService.rows
        switch gameService.playerCompletedGame() {
        case .player1:
            // TODO: Enhance Scoring by adding the non used balls for the winner as bonus
            endState = .winner(player1)
        case .player2:
            endState = .winner(player2!)
        case .none: break
        }
        
        scoreManagerPlayer1.updateScore(dict: player1CurrentResult, player: currentPlayer)
        scoreManagerPlayer2?.updateScore(dict: player2CurrentResult, player: currentPlayer)
    }
    
    private func reduceBallsByOne() {
        if currentPlayer == player1 {
            let player1BallsLeft = ballsLeft[player1] ?? 0
            ballsLeft[player1] = player1BallsLeft - 1
        } else {
            if let player2,
               let count = ballsLeft[player2] {
                ballsLeft[player2] = count-1
            }
        }
    }
    
    private func endGameIfOutOfBalls() {
        let player1BallsLeft = ballsLeft[player1] ?? 0
        var player2BallsLeft = 0
        if let player2,
           let count = ballsLeft[player2] {
            player2BallsLeft = count
        }
        guard player1BallsLeft < 1,
                player2BallsLeft < 1 else {
            return
        }
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
        reportSores()
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
        reportSores()
    }
    
    private func reportSores() {
        var winner: Player?
        switch endState {
        case .lost:
            //Play loosing sound playSound(.winner)
            break
        case .tie:
            playSound(.winner)
        case .winner(let player):
            playSound(.winner)
            winner = player
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
        restartBall()
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
        physicsService.setRollingObject(gameService.rollingObject)
        guard playerMode != .singlePlayer else {
            return
        }
        
        if playerMode == .againstComputer && currentPlayer != computer {
            currentPlayer = computer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if self?.endState == nil {
                    self?.computerMove()
                }
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
    
    private func restartBall() {
        (physicsService as? PersistingPhysicsService)?.addBall(of: selectedBallType)
        isBallMoving = false
    }

    func restartGame() {
        player1BallsSet = []
        player2BallsSet = []
        player1BallsPositionDict = [:]
        player2BallsPositionDict = [:]
        ballsLeft = [player1: config.ballsPerPlayer]
        if let p2 = player2 { ballsLeft[p2] = config.ballsPerPlayer }
        gameService.reset()
        currentPlayer = player1
        endState = nil
        rows = gameService.rows
        isBallMoving = false
        result = nil
        timerCancellable?.cancel()
        
        scoreManagerPlayer1.gameStarted()
        scoreManagerPlayer2?.gameStarted()
        physicsService.setRollingObject(gameService.rollingObject)
        physicsService.restart()
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
        guard !isBallMoving else {
            return
        }
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

extension PersistingGameViewModel: PhysicsServiceDelegate {
    func allBallsCameToRest() {
        calculatePositions()
        reduceBallsByOne()
        
        if endState == nil {
            endGameIfOutOfBalls()
            toggleTurn()
            restartBall()
        } else {
            reportSores()
        }
    }
    
    func created(_ ball: Ball) {
        FileLogger.shared.log("\(ball.name) was created! for \(currentPlayer.id)",
                              object: ball, level: .debug)
        if currentPlayer == player1 {
            player1BallsSet.insert(ball)
        } else {
            player2BallsSet.insert(ball)
        }
    }
    
    func ballStoppedMoving(_ ball: Ball, at position: CGPoint) {
        if player1BallsSet.contains(ball) {
            player1BallsPositionDict[ball] = position
        } else if player2BallsSet.contains(ball) {
            player2BallsPositionDict[ball] = position
        } else {
            FileLogger.shared.log("Ball is not assigned to a player", level: .error)
        }
        FileLogger.shared.log("Ball stopped at \(position)", object: ball, level: .verbose)
    }
}
