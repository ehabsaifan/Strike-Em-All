//
//  MainMenuView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

struct MainMenuView: View {
    let selectedPlayer: Player?
    @StateObject private var viewModel = MainMenuViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Roll Strike")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryColor)
                .padding(.top, 40)
            
            if let player = selectedPlayer {
                Text("Welcome, \(player.name)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Game mode picker.
            Picker("Game Mode", selection: $viewModel.playerMode) {
                Text("Single Player").tag(PlayerMode.singlePlayer)
                Text("Two Players").tag(PlayerMode.twoPlayers)
                Text("Vs. Computer").tag(PlayerMode.againstComputer)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Player name inputs.
            VStack(spacing: 12) {
                TextField("Player 1 Name", text: Binding(get: { viewModel.player1.name },
                                                            set: { viewModel.player1.name = $0 }))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if viewModel.playerMode == .twoPlayers {
                    TextField("Player 2 Name", text: Binding(get: { viewModel.player2.name },
                                                                set: { viewModel.player2.name = $0 }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
            }
            
            // Rolling object carousel.
            RollingObjectCarouselView(selectedBallType: $viewModel.rollingObjectType,
                                      settings: RollingObjectCarouselSettings()) {
                // Optionally handle selection done.
            }
            .padding(.horizontal)
            
            // Number of rows picker.
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Rows:")
                    .foregroundColor(AppTheme.secondaryColor)
                    .padding(.leading)
                Picker("Number of Rows", selection: $viewModel.selectedRowCount) {
                    ForEach(1...6, id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            // Toggle for wrap-around edges.
            Toggle("Pass through edges enabled", isOn: $viewModel.isWrapAroundEdgesEnabled)
                .padding(.horizontal)
            
            // Menu buttons for leaderboards and achievements.
            HStack(spacing: 20) {
                Button(action: {
                    GameCenterService.shared.showLeaderboard()
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
                    GameCenterService.shared.showAchievements()
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
            
            // Volume control.
            VolumeControlView(volume: $viewModel.volume)
                .padding()
                .opacity(0.7)
            
            Spacer()
            
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
        }
        .fullScreenCover(isPresented: $viewModel.showGameView) {
            GameView(viewModel: createGameViewModel())
        }
        .onAppear {
            if let selected = selectedPlayer {
                viewModel.player1 = selected
            }
        }
    }
    
    func createGameViewModel() -> GameViewModel {
        let rollingObject = viewModel.rollingObjectType.rollingObject
        let contentProvider = GameContentProvider(maxItems: viewModel.selectedRowCount)
        let gameService = GameService(rollingObject: rollingObject, contentProvider: contentProvider)
        let soundService = SoundService(category: viewModel.getSoundCategory())
        soundService.setVolume(viewModel.volume)
        
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.wrapAroundEnabled = viewModel.isWrapAroundEdgesEnabled
        let physicsService = SpriteKitPhysicsService(scene: gameScene)
        
        let gameViewModel = GameViewModel(
            gameService: gameService,
            physicsService: physicsService,
            soundService: soundService,
            gameScene: gameScene,
            playerMode: viewModel.playerMode,
            player1: viewModel.getPlayer1(),
            player2: viewModel.getPlayer2()
        )
        
        gameViewModel.startGame()
        return gameViewModel
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(selectedPlayer: Player(name: "Guest", type: .guest))
    }
}
