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
    @State private var showBallCarousel = false
    @State private var confettiCounter = 0
    @State private var showEarnedPoints = false
    @State private var earnedPointsText: String = ""
    @State private var showVolumeControl = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GameHeaderView(
                    player1: viewModel.player1,
                    player2: viewModel.gameMode == .singlePlayer ? nil : viewModel.player2,
                    currentPlayer: viewModel.currentPlayer,
                    player1Score: viewModel.score.total,
                    player2Score: viewModel.gameMode == .singlePlayer ? nil : viewModel.score.total,
                    onAction: { action in
                        switch action {
                        case .changeBall:
                            withAnimation { showBallCarousel = true }
                        case .changeVolume:
                            withAnimation { showVolumeControl = true }
                        case .quit:
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
                
                // Animated score view, game board, etc.
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
                                
                                if viewModel.gameMode != .singlePlayer {
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
                
                // Launch area.
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
                    message: Text("\(viewModel.winner?.name ?? "") Wins\nScore: \(viewModel.score.total)"),
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
            if showBallCarousel {
                RollingObjectCarouselView(selectedBallType: $viewModel.selectedBallType,
                                            settings: getCarouselSettings()) {
                    withAnimation { showBallCarousel = false }
                }
                .frame(height: 50)
                .zIndex(2)
            }
            
            if showVolumeControl {
                VolumeControlView(volume: $viewModel.volume)
                    .padding()
                    .shadow(radius: 10)
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showEarnedPoints {
                // You can set a custom starting offset (e.g., from the ball’s position) and a final offset.
                EarnedPointsView(
                    text: earnedPointsText,
                    // For example, have it end at an offset from the top:
                    finalOffset: CGSize(width: 30, height: -UIScreen.main.bounds.height / 3)
                )
                .zIndex(3)
            }
        }
        .onTapGesture {
            withAnimation {
                showVolumeControl = false
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    withAnimation {
                        showVolumeControl = false
                    }
                }
        )
        .onChange(of: viewModel.score.lastShotPointsEarned, initial: false) { _, newPoints in
            if newPoints > 0 {
                earnedPointsText = "+\(newPoints)"
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
    
    // Create a SpriteKit scene for physics
    let gameScene = GameScene(size: UIScreen.main.bounds.size)
    gameScene.scaleMode = .resizeFill
    let physicsService = SpriteKitPhysicsService(scene: gameScene)
    
    let viewModel = GameViewModel(gameService: gameService,
                                  physicsService: physicsService,
                                  soundService: soundService,
                                  gameScene: gameScene,
                                  gameMode: .twoPlayers,
                                  player1: .player(name: "Ehab"),
                                  player2: .computer)
    return viewModel
}
