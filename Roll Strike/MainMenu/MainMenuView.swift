//
//  MainMenuView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject private var viewModel: MainMenuViewModel

    init() {
        let contentProvider = GameContentProvider()
        _viewModel = StateObject(wrappedValue: MainMenuViewModel(contentProvider: contentProvider))
    }

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
            
            // Picker to choose the rolling object
            Picker("Select Rolling Object", selection: $viewModel.selectedRollingObjectType) {
                ForEach(RollingObjectType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Picker to choose the cell effect type
            Picker("Select Cell Effect", selection: $viewModel.selectedCellEffectType) {
                ForEach(CellEffectType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
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
        }
        .fullScreenCover(isPresented: $viewModel.showGameView) {
            GameView(viewModel: createGameViewModel())
        }
    }
    
    func createGameViewModel() -> GameViewModel {
        let rollingObject = viewModel.createRollingObject()
        let cellEffect = viewModel.createCellEffect()
        let contentProvider = GameContentProvider()
        let gameService = GameService(rollingObject: rollingObject,
                                      contentProvider: contentProvider)
        
        // Create a SpriteKit scene for physics
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        let physicsService = SpriteKitPhysicsService(scene: gameScene)
        
        let gameViewModel = GameViewModel(
            gameService: gameService,
            physicsService: physicsService,
            contentProvider: contentProvider,
            gameScene: gameScene,
            gameMode: viewModel.gameMode,
            player1: viewModel.getPlayer1(),
            player2: viewModel.getPlayer2(),
            cellEffect: cellEffect
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
