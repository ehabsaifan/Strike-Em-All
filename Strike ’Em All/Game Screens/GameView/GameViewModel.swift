//
//  GameViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
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
    
    @Published var rows: [GameRowProtocol] = []
    @Published var currentPlayer: Player
    @Published var result: GameResultInfo? = nil
    @Published var player1: Player
    @Published var player2: Player?
    @Published var playerMode: PlayerMode
    @Published var isBallMoving = false
    @Published var launchImpulse: CGVector? = nil
    @Published var rowFrames: [Int: CGRect] = [:]
    @Published var timeCounter: TimeInterval = 0
    @Published var scorePlayer1: Score = Score()
    @Published var scorePlayer2: Score = Score()
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
        didSet {
            soundService.setVolume(volume)
            SimpleDefaults.setValue(volume, forKey: .volumePref)
        }
    }
    
    var scoreManagerPlayer1: ScoreServiceProtocol
    var scoreManagerPlayer2: ScoreServiceProtocol?
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
    
    var timerEnabled: Bool {
        config.timerEnabled
    }
    
    let launchAreaVM: LaunchAreaViewModel
    let gameScene: GameScene
    let rowHeight: CGFloat = 70  // Used to calculate landing row
    
    private let config: GameConfiguration
    private let gameService: GameServiceProtocol
    private let physicsService: PhysicsServiceProtocol
    private let soundService: SoundServiceProtocol
    private let analyticsFactory: (Player) -> AnalyticsServiceProtocol
    
    private let gcReportService: GameCenterReportServiceProtocol?
    private let gameCenterService: GameCenterProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var started = false
    private var endState: EndState? = nil
    
    enum EndState: Codable, Equatable {
        case tie, lost(Player), winner(Player)
    }
    
    init(
        config: GameConfiguration,
        gameService: GameServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        soundService: SoundServiceProtocol,
        analyticsFactory: @escaping (Player) -> AnalyticsServiceProtocol,
        gcReportService: GameCenterReportServiceProtocol?,
        gameCenterService: GameCenterProtocol?,
        gameScene: GameScene
    ) {
        self.config = config
        self.gameService = gameService
        self.physicsService = physicsService
        self.soundService = soundService
        self.analyticsFactory = analyticsFactory
        self.gameCenterService = gameCenterService
        self.gcReportService = gcReportService
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
        var gcReportService1: GameCenterReportServiceProtocol?
        if config.player1.type == .gameCenter &&
            gameCenterService?.isAuthenticatedSubject.value == true {
            gcReportService1 = gcReportService
        }
        let analytics1 = analyticsFactory(config.player1)
        self.scoreManagerPlayer1 = ScoreService(
            calculator: config.timerEnabled ?
            TimedScoreCalculator(totalTime: config.timeLimit) : ScoreCalculator(),
            analyticsService: analytics1,
            gcReportService: gcReportService1)
        
        if config.playerMode != .singlePlayer,
           let secPlayer = config.player2 {
            var gcReportService2: GameCenterReportServiceProtocol?
            if config.player2?.type == .gameCenter &&
                gameCenterService?.isAuthenticatedSubject.value == true {
                gcReportService2 = gcReportService
            }
            let analytics2 = analyticsFactory(secPlayer)
            self.scoreManagerPlayer2 = ScoreService(
                calculator:  config.timerEnabled ?
                TimedScoreCalculator(totalTime: config.timeLimit) : ScoreCalculator(),
                analyticsService: analytics2,
                gcReportService: gcReportService2)
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
    
    private func updateRollingObject() {
        guard !isBallMoving else { return }
        physicsService.setRollingObject(gameService.rollingObject)
    }
    
    private func gotFinalPosition(_ finalPosition: CGPoint) {
        var success = false
        var winner: Player?
        let playerType: GameService.PlayerType = (currentPlayer == player1) ? .player1 : .player2
        
        if let rowIndex = getRowAtBallPosition(finalPosition: finalPosition) {
            success = gameService.markCell(at: rowIndex, forPlayer: playerType)
            if playerType == .player1 {
                if success { scoreManagerPlayer1.recordScore(atRow: rowIndex, player: player1) }
                else { scoreManagerPlayer1.missedShot(player: player1) }
            } else {
                if success { scoreManagerPlayer2?.recordScore(atRow: rowIndex, player: player2!) }
                else { scoreManagerPlayer2?.missedShot(player: player2!) }
            }
            rows = gameService.rows
            physicsService.resetBall()
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
            if playerType == .player1 { scoreManagerPlayer1.missedShot(player: player1) }
            else { scoreManagerPlayer2?.missedShot(player: player2!) }
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
                print("Winner by score should be \(winner!.name)")
            } else {
                let player1Rows = gameService.getRowsStatus(for: .player1)
                let player2Rows = gameService.getRowsStatus(for: .player2)
                if player1Rows.correctShots != player2Rows.correctShots {
                    winner = player1Rows.correctShots > player2Rows.correctShots ? player1: player2
                    endState = .winner(winner!)
                    print("Winner correct shots should be \(winner!.name)")
                } else if player1Rows.completedRows != player2Rows.completedRows {
                    winner = player1Rows.completedRows > player2Rows.completedRows ? player1: player2
                    endState = .winner(winner!)
                    print("Winner completed rows should be \(winner!.name)")
                }
            }
        }
        if endState == nil {
            endState = .tie
            print("Tie \(scorePlayer1.total) | \(scorePlayer2.total)")
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
        scoreManagerPlayer1.gameEnded(player: player1, isAWinner: (player1 == winner)) { [weak self] final in
            self?.scorePlayer1 = final
        }
        scoreManagerPlayer2?.gameEnded(player: player2!, isAWinner: (player2! == winner)) { [weak self] final in
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
        print("@@", analy)
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
        physicsService.resetBall()
        isBallMoving = false
    }
}

// MARK: - Public methods
extension GameViewModel {
    func reset() {
        gameService.reset()
        resetBall()
        currentPlayer = player1
        endState = nil
        
        rows = gameService.rows
        physicsService.setRollingObject(gameService.rollingObject)
        scoreManagerPlayer1.gameStarted(player: player1)
        scoreManagerPlayer2?.gameStarted(player: player2!)
        result = nil
        timerCancellable?.cancel()
        startTimer()
    }
    
    func startGame() {
        gameService.startGame(with: gameService.contentProvider.getSelectedContents())
        rows = gameService.rows
        physicsService.setRollingObject(gameService.rollingObject)
        scoreManagerPlayer1.gameStarted(player: player1)
        scoreManagerPlayer2?.gameStarted(player: player2!)
        startTimer()
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
    
    func getContent(for index: Int) -> GameContent {
        return gameService.contentProvider.getContent(for: index)
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
