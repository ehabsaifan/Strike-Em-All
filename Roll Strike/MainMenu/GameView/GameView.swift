//
//  GameView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showWinnerAlert = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar with close button and centered title
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .overlay(
                        Text("Roll Strike")
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                    )
                }
                
                HStack {
                    PlayerNameView(name: viewModel.player1.name, isActive: viewModel.currentPlayer == viewModel.player1)
                    
                    if viewModel.gameMode != .singlePlayer {
                        Spacer()
                        
                        PlayerNameView(name: viewModel.player2.name, isActive: viewModel.currentPlayer == viewModel.player2)
                    }
                }
                .padding(.horizontal)
                .padding([.top, .bottom], 8)
                
                // Game board
                VStack(spacing: 0) {
                    ForEach(0..<viewModel.rows.count, id: \.self) { index in
                        let row = viewModel.rows[index]
                        ZStack {
                            (index % 2 == 0 ? Color.white : Color(white: 0.95))
                            HStack(spacing: 0) {
                                GameCellView(marking: row.leftMarking,
                                             content: row.displayContent)
                                .animation(.easeInOut(duration: 0.3), value: row.leftMarking)
                                .frame(width: viewModel.rowHeight, height: viewModel.rowHeight)
                                .padding(.leading, 5)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: viewModel.rowHeight)
                                    .frame(maxWidth: .infinity)
                                
                                if viewModel.gameMode != .singlePlayer {
                                    GameCellView(marking: row.rightMarking,
                                                 content: row.displayContent)
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
            .alert(isPresented: $showWinnerAlert) {
                Alert(
                    title: Text("Game Over"),
                    message: Text("\(viewModel.winner?.name ?? "") Wins"),
                    dismissButton: .default(Text("OK")) { viewModel.reset() }
                )
            }
            .onChange(of: viewModel.winner, initial: false) { oldValue, newValue in
                showWinnerAlert = viewModel.winner != nil
            }
            .zIndex(0)
            
            // SpriteKit view for the ball (overlaid on top)
            SpriteView(scene: viewModel.gameScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)
        }
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
                                  contentProvider: contentProvider,
                                  gameScene: gameScene,
                                  gameMode: .twoPlayers,
                                  player1: .player(name: "Ehab"),
                                  player2: .computer)
    return viewModel
}

// MARK: - Subviews
struct PlayerNameView: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        Text(name)
            .font(.system(size: 16, weight: .medium))
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(isActive ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color(.systemGray5) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .animation(nil, value: isActive)
    }
}
