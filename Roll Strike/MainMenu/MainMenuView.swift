//
//  MainMenuView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel = MainMenuViewModel(contentProvider: GameContentProvider())

    var body: some View {
        VStack {
            Text("Roll Strike")
                .font(.largeTitle)
                .bold()
                .padding()
            
            // Game mode picker
            Picker("Game Mode", selection: $viewModel.gameMode) {
                Text("Single Player").tag(GameMode.singlePlayer)
                Text("Two Players").tag(GameMode.twoPlayers)
                Text("Against Computer").tag(GameMode.againstComputer)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Player name inputs
            TextField("Player 1 Name", text: $viewModel.player1Name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if viewModel.gameMode == .twoPlayers {
                TextField("Player 2 Name", text: $viewModel.player2Name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            
            Picker("Sound Category", selection: $viewModel.soundCategory) {
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            
            RollingObjectCarouselView(selectedBallType: $viewModel.rollingObjectType, settings: RollingObjectCarouselSettings()) {}
                .padding()
            
            VStack(alignment: .leading) {
                Text("Number of rows:")
                Picker("Number of Rows", selection: $viewModel.selectedRowCount) {
                    ForEach(1...6, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            Toggle("Pass through edges enabled", isOn: $viewModel.isWrapAroundEdgesEnabled)
            .padding()
            
            Button(action: { viewModel.showGameView = true }) {
                Text("Start Game")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            
            Button("View Leaderboard") {
                GameCenterManager.shared.showLeaderboard()
            }
            .buttonStyle(.borderedProminent)
            
            Button("View Achievements") {
                GameCenterManager.shared.showAchievements()
            }
            .buttonStyle(.bordered)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .fullScreenCover(isPresented: $viewModel.showGameView) {
            GameView(viewModel: createGameViewModel())
        }
        .onAppear() {
            GameCenterManager.shared.authenticateLocalPlayer()
        }
    }
    
    func createGameViewModel() -> GameViewModel {
        let rollingObject = viewModel.rollingObjectType.rollingObject
        let contentProvider = GameContentProvider(maxItems: viewModel.selectedRowCount)
        let gameService = GameService(rollingObject: rollingObject,
                                      contentProvider: contentProvider)
        let soundService = SoundService(category: viewModel.getSoundCategory())
        
        // Create a SpriteKit scene for physics
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.wrapAroundEnabled = viewModel.isWrapAroundEdgesEnabled
        let physicsService = SpriteKitPhysicsService(scene: gameScene)
        
        let gameViewModel = GameViewModel(
            gameService: gameService,
            physicsService: physicsService,
            soundService: soundService,
            contentProvider: contentProvider,
            gameScene: gameScene,
            gameMode: viewModel.gameMode,
            player1: viewModel.getPlayer1(),
            player2: viewModel.getPlayer2()
        )
        
        gameViewModel.startGame(with: viewModel.getTargets())
        return gameViewModel
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
