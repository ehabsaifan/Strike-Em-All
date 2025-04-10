//
//  MainMenuView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title Section
            Text("Roll Strike")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryColor)
                .padding(.top, 40)
            
            // Game Mode Picker
            Picker("Game Mode", selection: $viewModel.gameMode) {
                Text("Single Player").tag(GameMode.singlePlayer)
                Text("Two Players").tag(GameMode.twoPlayers)
                Text("Vs. Computer").tag(GameMode.againstComputer)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Player Name Inputs
            VStack(spacing: 12) {
                TextField("Player 1 Name", text: $viewModel.player1Name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if viewModel.gameMode == .twoPlayers {
                    TextField("Player 2 Name", text: $viewModel.player2Name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
            }
            
            // Rolling Object Carousel
            RollingObjectCarouselView(selectedBallType: $viewModel.rollingObjectType,
                                      settings: RollingObjectCarouselSettings()) {
                // Optionally handle selection done
            }
            .padding(.horizontal)
            
            // Row count setting (if needed)
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Rows:")
                    .foregroundColor(AppTheme.secondaryColor)
                    .padding(.leading)
                Picker("Number of Rows", selection: $viewModel.selectedRowCount) {
                    ForEach(1...6, id: \.self) { number in
                        Text("\(number)")
                            .tag(number)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            // Toggle for wrap-around edges
            Toggle("Pass through edges enabled", isOn: $viewModel.isWrapAroundEdgesEnabled)
                .padding(.horizontal)
            
            // Menu Buttons
            HStack(spacing: 20) {
                Button(action: {
                    GameCenterManager.shared.showLeaderboard()
                }) {
                    Text("Leaderboard")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.secondaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    GameCenterManager.shared.showAchievements()
                }) {
                    Text("Achievements")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.secondaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            VolumeControlView(volume: $viewModel.volume)
                .padding()
                .opacity(0.7)
            
            // Start Game Button
            Button(action: { viewModel.showGameView = true }) {
                Text("Start Game")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(AppTheme.tertiaryColor.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            hideKeyboard()
        }
        .fullScreenCover(isPresented: $viewModel.showGameView) {
            GameView(viewModel: createGameViewModel())
        }
        .onAppear {
            GameCenterManager.shared.authenticateLocalPlayer()
        }
    }
    
    func createGameViewModel() -> GameViewModel {
        let rollingObject = viewModel.rollingObjectType.rollingObject
        let contentProvider = GameContentProvider(maxItems: viewModel.selectedRowCount)
        let gameService = GameService(rollingObject: rollingObject,
                                      contentProvider: contentProvider)
        let soundService = SoundService(category: viewModel.getSoundCategory())
        soundService.setVolume(viewModel.volume)
        // Create a SpriteKit scene for physics
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.wrapAroundEnabled = viewModel.isWrapAroundEdgesEnabled
        let physicsService = SpriteKitPhysicsService(scene: gameScene)
        
        let gameViewModel = GameViewModel(
            gameService: gameService,
            physicsService: physicsService,
            soundService: soundService,
            gameScene: gameScene,
            gameMode: viewModel.gameMode,
            player1: viewModel.getPlayer1(),
            player2: viewModel.getPlayer2()
        )
        
        gameViewModel.startGame()
        return gameViewModel
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
