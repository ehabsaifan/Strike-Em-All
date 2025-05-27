//
//  GameSettingsView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/16/25.
//

import SwiftUI

struct GameSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.di) private var di
    @Environment(\.dismiss) private var dismiss
    
    @Binding var config: GameConfiguration
    
    // sheet / alert / start‐game state
    @State private var showingPlayerPicker: PlayerMode?
    @State private var showingSignInAlert = false
    @State private var isSigningIn = false
    @State private var showGame = false
    @StateObject private var vmHolder = GameViewModelHolder()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        PlayerModePickerView(playerMode: $config.playerMode)
                        
                        VStack(spacing: 16) {
                            PlayerCardView(title: "Player 1",
                                           player: config.player1,
                                           placeholder: "You") {
                                cardTapped(.singlePlayer)
                            }
                            
                            if config.playerMode == .twoPlayers {
                                PlayerCardView(title: "Player 2",
                                               player: config.player2,
                                               placeholder: "Select Opponent") {
                                    cardTapped(.twoPlayers)
                                }
                            } else if config.playerMode == .againstComputer {
                                ComputerCardView()
                            }
                            
                            if config.playerMode == .twoPlayers,
                               config.player2 != nil,
                               config.player2 != computer {
                                Button("Swap Players") {
                                    config.swapPlayers()
                                    appState.currentConfig?.player1 = config.player1
                                    appState.currentConfig?.player2 = config.player2
                                    appState.currentPlayer = config.player1
                                }
                                .buttonStyle(.bordered)
                                .tint(AppTheme.secondaryColor)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        
                        RollingObjectSettingsView(config: $config)
                        
                        ModeSpecificSettingsView(config: $config)
                        
                        CommonSettingsView(config: $config)
                        
                        SoundSettingsView(config: $config)
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.vertical)
                }
                
                VStack {
                    Spacer()
                    Button {
                        let vm = makeGameViewModel()
                        vmHolder.viewModel = vm
                        vm.startGame()
                        showGame = true
                    } label: {
                        Text("Start")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.secondaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .shadow(color: Color.black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: -4)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(appState.currentPlayer == nil)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(item: $showingPlayerPicker) { slot in
                PlayerSelectionView(selectedPlayer: Binding(
                    get: { slot == .singlePlayer ? Optional(config.player1) : config.player2 },
                    set: { new in
                        guard new?.id != config.player1.id else { return }
                        if slot == .singlePlayer, let p = new {
                            config.player1 = p
                            appState.currentConfig?.player1 = p
                            appState.currentPlayer = p
                        } else {
                            config.player2 = new
                            appState.currentConfig?.player2 = new
                        }
                        if let p = new, p.type == .gameCenter,
                           !di.authService.isAuthenticatedSubject.value {
                            showingSignInAlert = true
                        }
                    })) {
                        showingPlayerPicker = nil
                    }
                    .environment(\.di, di)
            }
            .alert("Game Center Sign-In", isPresented: $showingSignInAlert) {
                Button("Sign In") {
                    isSigningIn = true
                    di.authService.authenticate { success, _ in
                        isSigningIn = false
                        if !success {
                            if showingPlayerPicker == .singlePlayer {
                                /* clear if needed */
                            } else {
                                config.player2 = nil
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    showingPlayerPicker = nil
                }
            } message: {
                Text("Please sign in to Game Center to report your score and achievements.")
            }
            .fullScreenCover(isPresented: $showGame) {
                if let vm = vmHolder.viewModel {
                    GameView(viewModel: vm)
                }
            }
            .overlay {
                if isSigningIn {
                    ZStack {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.3)
                            
                            Text("Signing in…")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func cardTapped(_ slot: PlayerMode) {
        let candidate = slot == .singlePlayer ? config.player1 : config.player2
        if let p = candidate, p.type == .gameCenter,
           !di.authService.isAuthenticatedSubject.value {
            showingSignInAlert = true
            return
        }
        
        showingPlayerPicker = slot
    }
    
    private func makeGameViewModel() -> GameViewModel {
        let cp = GameContentProvider(maxItems: config.rowCount)
        let gs = GameService(rollingObject: config.rollingObjectType.rollingObject,
                             contentProvider: cp)
        let ss = SoundService(category: config.soundCategory)
        ss.setVolume(config.volume)
        
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.wrapAroundEnabled = config.wrapEnabled
        let phys = SpriteKitPhysicsService(scene: scene)
        
        return GameViewModel(config: config,
                             gameService: gs,
                             physicsService: phys,
                             soundService: ss,
                             analyticsFactory: di.analyticsFactory,
                             gcReportService: di.gcReportService,
                             gameCenterService: di.gameCenter,
                             gameScene: scene)
    }
}

private class GameViewModelHolder: ObservableObject {
    @Published var viewModel: GameViewModel?
}


// MARK: — PlayerModePickerView

struct PlayerModePickerView: View {
    @Binding var playerMode: PlayerMode
    
    var body: some View {
        SectionBlock(title: "Player Mode") {
            Picker("Player Mode", selection: $playerMode) {
                ForEach(PlayerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: — PlayerCardView



// MARK: — ModeSpecificSettingsView

struct ModeSpecificSettingsView: View {
    @Binding var config: GameConfiguration
    
    var body: some View {
        SectionBlock(title: config.mode.title) {
            VStack(spacing: 12) {
                switch config.mode {
                case .classic,
                        .persisting:
                    Stepper("Rows: \(config.rowCount)",
                            value: $config.rowCount,
                            in: 1...config.maxNumberOfRows.count)
                case .dartboard:
                    Stepper("Rings: \(config.ringCount)",
                            value: $config.ringCount,
                            in: 1...8)
                case .multiCircle:
                    Stepper("Rings: \(config.ringCount)",
                            value: $config.ringCount,
                            in: 1...6)
                    Stepper("Balls/Player: \(config.ballsPerPlayer)",
                            value: $config.ballsPerPlayer,
                            in: 1...5)
                }
            }
        }
    }
}

// MARK: — CommonSettingsView

struct CommonSettingsView: View {
    @Binding var config: GameConfiguration
    
    var body: some View {
        SectionBlock(title: "Common") {
            VStack(spacing: 12) {
                Toggle("Timed Mode", isOn: $config.isTimed)
                    .tint(AppTheme.secondaryColor)
                if config.isTimed {
                    Picker("Time Limit", selection: $config.timeLimit) {
                        ForEach(config.timeOptions, id: \.self) {
                            Text("\(Int($0))s").tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Toggle("Wrap Around Edges", isOn: $config.wrapEnabled)
                    .tint(AppTheme.secondaryColor)
            }
        }
    }
}

struct RollingObjectSettingsView: View {
    @Binding var config: GameConfiguration
    
    var body: some View {
        SectionBlock(title: "Rolling object") {
            RollingObjectCarouselView(
                selectedBallType: $config.rollingObjectType,
                settings: RollingObjectCarouselSettings(
                    segmentSettings: CustomSegmentedControlSettings(
                        selectedTintColor: UIColor(AppTheme.secondaryColor),
                        normalTextColor: .black,
                        selectedTextColor: .white
                    )
                )
            ) { }
        }
    }
}

struct SoundSettingsView: View {
    @Binding var config: GameConfiguration
    
    var body: some View {
        SectionBlock(title: "Sound") {
            VolumeControlView(volume: $config.volume)
        }
    }
}
