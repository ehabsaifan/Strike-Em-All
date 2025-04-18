//
//  GameView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import SpriteKit
import ConfettiSwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showWinnerAlert = false
    @State private var confettiCounter = 0
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
                
                VStack(spacing: 0) {
                    ForEach(0..<viewModel.rows.count, id: \.self) { index in
                        let row = viewModel.rows[index]
                        ZStack {
                            (index % 2 == 0 ? Color.white : Color(white: 0.95))
                            HStack(spacing: 0) {
                                GameCellView(marking: row.leftMarking, content: row.displayContent)
                                    .animation(.easeInOut(duration: 0.3), value: row.leftMarking)
                                    .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                    .padding(.leading, 5)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: viewModel.rowHeight)
                                    .frame(maxWidth: .infinity)
                                
                                if viewModel.playerMode != .singlePlayer {
                                    GameCellView(marking: row.rightMarking, content: row.displayContent)
                                        .animation(.easeInOut(duration: 0.3), value: row.rightMarking)
                                        .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                        .padding(.trailing, 5)
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
                }
                .frame(maxWidth: .infinity)
                .onPreferenceChange(RowFramePreferenceKey.self) { frames in
                    viewModel.rowFrames = frames
                }
                
                Spacer()
                
                LaunchAreaView(viewModel: viewModel.launchAreaVM)
                    .frame(height: GameViewModel.launchAreaHeight)
            }
            .confettiCannon(trigger: $confettiCounter,
                              num: 150,
                              openingAngle: Angle(degrees: 0),
                              closingAngle: Angle(degrees: 360),
                              radius: 250)
            .background(AppTheme.tertiaryColor.edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showWinnerAlert) {
                Alert(
                    title: Text("Game Over"),
                    message: Text("\(viewModel.winner?.name ?? "") Wins\nScore: \(viewModel.winnerFinalScore.total)"),
                    dismissButton: .default(Text("OK")) {
                        viewModel.reset()
                    }
                )
            }
            .onChange(of: viewModel.winner, initial: false) { _, _ in
                if viewModel.winner != nil {
                    showWinnerAlert = true
                    confettiCounter += 1
                } else {
                    showWinnerAlert = false
                }
            }
            .zIndex(0)
            
            // SpriteKit view for ball simulation.
            SpriteView(scene: viewModel.gameScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)
            
            // Ball selection carousel.
            if activeOverlay == .ballSelection {
                RollingObjectCarouselView(selectedBallType: $viewModel.selectedBallType,
                                            settings: getCarouselSettings()) {
                    withAnimation { activeOverlay = .none }
                }
                .frame(height: 50)
                .zIndex(2)
            }
            
            if activeOverlay == .volumeControl {
                VolumeControlView(volume: $viewModel.volume)
                    .padding()
                    .shadow(radius: 10)
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showEarnedPoints {
                EarnedPointsView(
                    text: earnedPointsText,
                    finalOffset: CGSize(width: 30, height: -UIScreen.main.bounds.height / 3)
                )
                .zIndex(3)
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
            if newScore.lastShotPointsEarned > 0 {
                earnedPointsText = "+\(newScore.lastShotPointsEarned)"
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
            if newScore.lastShotPointsEarned > 0 {
                earnedPointsText = "+\(newScore.lastShotPointsEarned)"
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
    }
    
    private func getCarouselSettings() -> RollingObjectCarouselSettings {
        RollingObjectCarouselSettings(
            segmentSettings: CustomSegmentedControlSettings(selectedTintColor: .yellow),
            backGroundColor: .orange
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
    
    let config = GameConfiguration(playerMode: .twoPlayers,
                                   player1: Player(name: "Ehab", type: .guest),
                                   player2: computer,
                                   soundCategory: .street,
                                   wrapEnabled: false,
                                   timed: false,
                                   rollingObjectType: .beachBall,
                                   rowCount: 5,
                                   volume: 1)
    
    let viewModel = GameViewModel(config: config,
                                  gameService: gameService,
                                  physicsService: physicsService,
                                  soundService: soundService,
                                  gameScene: gameScene)
    return viewModel
}
