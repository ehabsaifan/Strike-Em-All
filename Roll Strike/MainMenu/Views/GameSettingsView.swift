//
//  GameSettingsView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/16/25.
//

import SwiftUI

struct GameSettingsView: View {
    @Environment(\.di) private var di
    
    @Binding var config: GameConfiguration
    
    @State private var showGameView = false
    @StateObject private var vmHolder = GameViewModelHolder()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RollingObjectCarouselView(
                    selectedBallType: $config.rollingObjectType,
                    settings: RollingObjectCarouselSettings()
                ) { }
                
                Divider().background(Color.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("How many rows would you like to play?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Picker("Number of Rows", selection: $config.rowCount) {
                        ForEach(1..<7, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable object to pass through edges")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Toggle("Wrap Around Edges", isOn: $config.wrapEnabled)
                        .tint(AppTheme.secondaryColor)
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable to race against the clock.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Toggle("Timed Mode", isOn: $config.timed)
                        .tint(AppTheme.secondaryColor)
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                //                Picker("Sound Category", selection: $config.soundCategory) {
                //                    ForEach(SoundCategory.allCases, id: \.self) {
                //                        Text($0.title).tag($0)
                //                    }
                //                }
                //                .pickerStyle(.menu)
                
                //                Divider().background(Color.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adjust game sound volume")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    VolumeControlView(volume: $config.volume)
                }
                                
                Divider().background(Color.gray.opacity(0.3))
                Spacer()
                
                Button(action: {
                    let vm = makeGameViewModel()
                    vmHolder.viewModel = vm
                    vm.startGame()
                    showGameView = true
                }) {
                    Text("Start Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundColor(.white)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(8)
                        .fullScreenCover(isPresented: $showGameView) {
                            if let vm = vmHolder.viewModel {
                                GameView(viewModel: vm)
                            }
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
    
    private func makeGameViewModel() -> GameViewModel {
        // 1. ContentProvider seeded with rowCount
        let contentProvider = GameContentProvider(maxItems: config.rowCount)
        
        // 2. GameService seeded with the chosen rollingObject
        let gameService = GameService(
            rollingObject: config.rollingObjectType.rollingObject,
            contentProvider: contentProvider
        )
        
        // 3. SoundService seeded with soundCategory & volume
        let soundService = SoundService(category: config.soundCategory)
        soundService.setVolume(config.volume)
        
        // 4. Reuse the shared scene
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.wrapAroundEnabled = config.wrapEnabled
        let physicsService = SpriteKitPhysicsService(scene: gameScene)
        
        // 5. Inject config & services into ViewModel
        return GameViewModel(
            config: config,
            gameService: gameService,
            physicsService: physicsService,
            soundService: soundService,
            analyticsFactory: di.analyticsFactory,
            achievementService: di.achievementService,
            gameCenterService: di.gameCenter,
            gameScene: gameScene
        )
    }
}

private class GameViewModelHolder: ObservableObject {
    @Published var viewModel: GameViewModel?
}
