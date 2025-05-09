//
//  GameView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEarnedPoints = false
    @State private var earnedPointsText: String = ""
    @State private var activeOverlay: ActiveOverlay = .none
    
    enum ActiveOverlay {
        case none
        case ballSelection
        case volumeControl
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
                    enableBouncing: viewModel.timerEnabled,
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
                                
                                if viewModel.playerMode != .singlePlayer {
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
                    .frame(height: GameViewModel.launchAreaHeight)
            }
            .sheet(item: $viewModel.result) { result in
                GameResultView(
                    result: result,
                    onAction: { action in
                        switch action {
                        case .restart:
                            viewModel.reset()
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
    GameView(viewModel: createGameViewModel())
}

private func createGameViewModel() -> GameViewModel {
    let contentProvider = GameContentProvider()
    let gameService = GameService(rollingObject: Ball(),
                                  contentProvider: contentProvider)
    let soundService = SoundService(category: .street)
    
    let gameScene = GameScene(size: UIScreen.main.bounds.size)
    gameScene.scaleMode = .resizeFill
    let physicsService = SpriteKitPhysicsService(scene: gameScene)
    
    let di = PreviewContainer()
    let config = GameConfiguration(playerMode: .twoPlayers,
                                   player1: Player(name: "Ehab", type: .guest),
                                   player2: computer,
                                   soundCategory: .street,
                                   wrapEnabled: false,
                                   rollingObjectType: .beachBall,
                                   rowCount: 5,
                                   volume: 1)
    
    let viewModel = GameViewModel(config: config,
                                  gameService: gameService,
                                  physicsService: physicsService,
                                  soundService: soundService,
                                  analyticsFactory: di.analyticsFactory,
                                  gcReportService: di.gcReportService,
                                  gameCenterService: di.gameCenter,
                                  gameScene: gameScene)
    return viewModel
}

struct PreviewContainer: DIContainer {
    let authService: AuthenticationServiceProtocol = GameCenterService.shared
    let gameCenter: GameCenterProtocol   = GameCenterService.shared
    let playerRepo: PlayerRepositoryProtocol = PlayerService.shared
    let gcReportService: GameCenterReportServiceProtocol = GameCenterReportService(gcService: GameCenterService.shared)
    
    // **Instead** of a single AnalyticsService, expose a factory:
    let analyticsFactory: (String) -> AnalyticsServiceProtocol = { recordName in
        AnalyticsService(recordName: recordName)
    }
}
