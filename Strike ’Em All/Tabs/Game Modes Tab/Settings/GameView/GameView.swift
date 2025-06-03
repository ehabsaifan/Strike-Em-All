//
//  GameView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import SpriteKit

struct GameView<VM: GameViewModelProtocol>: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: VM
    @Environment(\.presentationMode) var presentationMode
    @State private var showEarnedPoints = false
    @State private var earnedPointsText: String = ""
    @State private var activeOverlay: ActiveOverlay = .none
    
    enum ActiveOverlay {
        case none
        case ballSelection
        case volumeControl
    }
    
    init(viewModel: VM) {
        // 2) Initialize the @StateObject backing store
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GameHeaderView(
                    player1: viewModel.player1,
                    player2: viewModel.playerMode == .singlePlayer ? nil : viewModel.player2,
                    currentPlayer: viewModel.currentPlayer,
                    player1Score: viewModel.scorePlayer1,
                    player2Score: viewModel.scorePlayer2,
                    timeCounter: viewModel.timeCounter,
                    enableBouncing: viewModel.isTimed,
                    onAction: { action in
                        switch action {
                        case .changeBall:
                            activeOverlay = .ballSelection
                        case .changeVolume:
                            activeOverlay = .volumeControl
                        case .quit:
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
                Divider()
                    .background(AppTheme.primaryColor)
                VStack(spacing: 0) {
                    ForEach(0..<viewModel.rows.count, id: \.self) { index in
                        let row = viewModel.rows[index]
                        Divider()
                        ZStack {
                            if viewModel.playerMode == .singlePlayer {
                                ZStack {
                                    Rectangle()
                                        .foregroundStyle(AppTheme.tertiaryColor)
                                        .frame(height: viewModel.rowHeight)
                                        .frame(maxWidth: .infinity)
                                    HStack {
                                        Spacer()
                                        GameCellView(marking: row.leftMarking, content: row.displayContent)
                                            .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                            .background(AppTheme.tertiaryColor)
                                        Spacer()
                                    }
                                }
                            } else {
                                HStack(spacing: 0) {
                                    GameCellView(marking: row.leftMarking, content: row.displayContent)
                                        .animation(.easeInOut(duration: 0.3), value: row.leftMarking)
                                        .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                        .padding(.leading, 5)
                                        .background(AppTheme.tertiaryColor)
                                    
                                    Divider()
                                    
                                    Rectangle()
                                        .foregroundStyle(AppTheme.tertiaryColor)
                                        .frame(height: viewModel.rowHeight)
                                        .frame(maxWidth: .infinity)
                                    
                                    Divider()
                                    GameCellView(marking: row.rightMarking, content: row.displayContent)
                                        .animation(.easeInOut(duration: 0.3), value: row.rightMarking)
                                        .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                        .padding(.trailing, 5)
                                        .background(AppTheme.tertiaryColor)
                                }
                            }
                        }
                        .frame(height: viewModel.rowHeight)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: RowFramePreferenceKey.self, value: [index: geo.frame(in: .global)])
                            }
                        )
                    }
                    Divider()
                }
                .frame(maxWidth: .infinity)
                .onPreferenceChange(RowFramePreferenceKey.self) { frames in
                    viewModel.rowFrames = frames
                }
                
                Spacer()
                
                LaunchAreaView(viewModel: viewModel.launchAreaVM)
                    .frame(height: GameViewConstants.launchAreaHeight)
            }
            .sheet(item: $viewModel.result) { result in
                GameResultView(
                    result: result,
                    onAction: { action in
                        switch action {
                        case .restart:
                            viewModel.restartGame()
                        case .quit:
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .zIndex(0)
            
            // SpriteKit view for ball simulation.
            SpriteView(scene: viewModel.gameScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)
            
            VStack {
                Spacer()
                HStack {
                    BallsRemainingOverlay(
                        p1Count: viewModel.player1BallsLeft,
                        p2Count: viewModel.player2 == nil ? 0 : viewModel.player2BallsLeft
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            if showEarnedPoints {
                EarnedPointsView(
                    text: earnedPointsText,
                    finalOffset: CGSize(width: 30, height: -UIScreen.main.bounds.height / 3)
                )
                .zIndex(4)
            }
        }
        .onTapGesture {
            withAnimation {
                activeOverlay = .none
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    withAnimation {
                        activeOverlay = .none
                    }
                }
        )
        .onChange(of: viewModel.scorePlayer1, initial: false) { oldScore, newScore in
            if newScore.currentShotEarnedpoints > 0 {
                earnedPointsText = "+\(newScore.currentShotEarnedpoints)"
                withAnimation(.easeOut(duration: 0.6)) {
                    showEarnedPoints = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showEarnedPoints = false
                    }
                }
            }
        }
        .onChange(of: viewModel.scorePlayer2, initial: false) { oldScore, newScore in
            if newScore.currentShotEarnedpoints > 0 {
                earnedPointsText = "+\(newScore.currentShotEarnedpoints)"
                withAnimation(.easeOut(duration: 0.6)) {
                    showEarnedPoints = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showEarnedPoints = false
                    }
                }
            }
        }
        .overlay(
            Group {
                if activeOverlay == .ballSelection {
                    RollingObjectCarouselView(
                        selectedBallType: $viewModel.selectedBallType,
                        settings: getCarouselSettings()
                    ) {}
                        .padding()
                        .transition(.opacity)
                }
            },
            alignment: .center
        )
        .overlay(
            Group {
                if activeOverlay == .volumeControl {
                    VolumeControlView(volume: $viewModel.volume)
                        .padding()
                        .transition(.opacity)
                        .shadow(radius: 10)
                }
            },
            alignment: .center
        )
    }
    
    private func getCarouselSettings() -> RollingObjectCarouselSettings {
        RollingObjectCarouselSettings(
            segmentSettings: CustomSegmentedControlSettings(
                selectedTintColor: UIColor(AppTheme.secondaryColor),
                normalTextColor: .black,
                selectedTextColor: .white),
            backGroundColor: AppTheme.primaryColor
        )
    }
}

#Preview {
    GameView(viewModel: createPreviewGameViewModel())
}

private func createPreviewGameViewModel() -> ClassicGameViewModel {
    let contentProvider = GameContentProvider()
    let gameService = GameService(rollingObject: BeachBall(),
                                  contentProvider: contentProvider)
    let soundService = SoundService(category: .street)
    
    let gameScene = ClassicGameScene(size: UIScreen.main.bounds.size)
    gameScene.scaleMode = .resizeFill
    let physicsService = ClassicPhysicsService(scene: gameScene)
    
    let di = PreviewContainer()
    let config = GameConfiguration(player1: Player(name: "Ehab", type: .guest))
    let viewModel = ClassicGameViewModel(config: config,
                                  gameService: gameService,
                                  physicsService: physicsService,
                                  soundService: soundService,
                                  analyticsFactory: di.analyticsFactory,
                                  gcReportService: di.gcReportService,
                                  gameCenterService: di.gameCenter,
                                  gameScene: gameScene)
    return viewModel
}

class PreviewContainer: DIContainer {
    let authService: AuthenticationServiceProtocol
    let gameCenter: GameCenterProtocol
    let cloud: CloudSyncServiceProtocol
    let playerRepo: PlayerRepositoryProtocol
    let gcReportService: GameCenterReportServiceProtocol
    let analyticsDisk: Persistence
    let cloudCheckingService: CloudAvailabilityChecking
    let appMetaData: AppMetadata
    
    private var analyticsCache: [Player: AnalyticsServiceProtocol] = [:]
    
    init() {
        let cloud = CloudSyncService()
        let disk = FileStorage(subfolder: "Preview")
        self.authService           = GameCenterService.shared
        self.gameCenter            = GameCenterService.shared
        self.analyticsDisk         = FileStorage()
        self.cloud                 = cloud
        self.playerRepo            = PlayerService(disk: disk, cloudSyncService: cloud)
        self.gcReportService       = GameCenterReportService(gcService: GameCenterService.shared)
        self.cloudCheckingService  = CloudAvailabilityService()
        self.appMetaData = AppMetadata()
    }
    
    /// 3) Factory that reuses existing services
    lazy var analyticsFactory: (Player) -> AnalyticsServiceProtocol = { [unowned self] player in
        if let existing = analyticsCache[player] {
            return existing
        }
        let newService = AnalyticsService(
            disk: analyticsDisk,
            player: player,
            cloud: cloud,
            availability: cloudCheckingService
        )
        analyticsCache[player] = newService
        return newService
    }
}

struct BallsRemainingOverlay: View {
    let p1Count: Int
    let p2Count: Int
    
    // Use whatever colors you assigned as your “player 1” and “player 2” border tints:
    private let p1Color = Color.red.opacity(0.8)
    private let p2Color = Color.blue.opacity(0.8)
    
    var body: some View {
        HStack(spacing: 16) {
            // Player 1’s indicator
            HStack(spacing: 4) {
                // Mini ball icon (you can replace with Image("beachBall-icon") if you have one)
                Circle()
                    .strokeBorder(p1Color, lineWidth: 2)
                    .background(Circle().fill(Color.white.opacity(0.9)))
                    .frame(width: 20, height: 20)
                Text("× \(p1Count)")
                    .font(.footnote).bold()
                    .foregroundColor(p1Color)
            }
            
            // Player 2’s indicator (only show if there is a second player)
            if p2Count > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .strokeBorder(p2Color, lineWidth: 2)
                        .background(Circle().fill(Color.white.opacity(0.9)))
                        .frame(width: 20, height: 20)
                    Text("× \(p2Count)")
                        .font(.footnote).bold()
                        .foregroundColor(p2Color)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
        )
        .padding(.bottom, 20)
    }
}
