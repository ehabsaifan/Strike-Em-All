//
//  GameSettingsView.swift
//  Strike ’Em All
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
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    SectionBlock(
                        title: "Choose Rolling Object",
                        content: {
                            RollingObjectCarouselView(
                                selectedBallType: $config.rollingObjectType,
                                settings: RollingObjectCarouselSettings(segmentSettings: CustomSegmentedControlSettings(
                                    selectedTintColor: UIColor(AppTheme.secondaryColor),
                                    normalTextColor: .black,
                                    selectedTextColor: UIColor(AppTheme.secondaryColor)))) { }
                        }
                    )
                    
                    SectionBlock(
                        title: "Choose number of rows",
                        content: {
                            CustomSegmentedControl(selectedSegment: $config.rowCount,
                                                   items: config.maxNumberOfRows,
                                                   label: { "\($0)" },
                                                   settings: CustomSegmentedControlSettings(
                                                    selectedTintColor: UIColor(AppTheme.secondaryColor),
                                                    normalTextColor: .black,
                                                    selectedTextColor: .white))
                        }
                    )
                    
                    SectionBlock(
                        title: "Enable object to pass through edges",
                        content: {
                            Toggle("Wrap Around Edges", isOn: $config.wrapEnabled)
                                .tint(AppTheme.secondaryColor)
                        }
                    )
                    
                    SectionBlock(
                        title: "Enable to race against the clock.",
                        content: {
                            Toggle("Timed Mode", isOn: $config.timerEnabled)
                                .tint(AppTheme.secondaryColor)
                            if config.timerEnabled {
                                CustomSegmentedControl(selectedSegment: $config.timeLimit,
                                                       items: config.timeOptions,
                                                       label: { "\(Int($0))" },
                                                       settings: CustomSegmentedControlSettings(
                                                        selectedTintColor: UIColor(AppTheme.secondaryColor),
                                                        normalTextColor: .black,
                                                        selectedTextColor: .white))
                                .padding(.top, 4)
                            }
                        }
                    )
                    
                    //Divider()
                    //                Picker("Sound Category", selection: $config.soundCategory) {
                    //                    ForEach(SoundCategory.allCases, id: \.self) {
                    //                        Text($0.title).tag($0)
                    //                    }
                    //                }
                    //                .pickerStyle(.menu)
                    
                    //                Divider()
                    
                    SectionBlock(
                        title: "Adjust game sound volume",
                        content: {
                            VolumeControlView(volume: $config.volume)
                        }
                    )
                }
            }
            
            Button(action: {
                let vm = makeGameViewModel()
                vmHolder.viewModel = vm
                vm.startGame()
                showGameView = true
            }) {
                Text("Start Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryColor)
                    .cornerRadius(8)
                
            }
            .shadow(color: Color.black.opacity(0.25),
                    radius: 4,
                    x: 0,
                    y: -4)
            .fullScreenCover(isPresented: $showGameView) {
                if let vm = vmHolder.viewModel {
                    GameView(viewModel: vm)
                }
            }
            .padding([.top, .leading, .trailing])
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
            gcReportService: di.gcReportService,
            gameCenterService: di.gameCenter,
            gameScene: gameScene
        )
    }
}

private class GameViewModelHolder: ObservableObject {
    @Published var viewModel: GameViewModel?
}
