//
//  LandingView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import SwiftUI

struct LandingView: View {
    @StateObject var viewModel = LandingViewModel()
    @State private var navigateToFlow = false
    @State private var guestName: String = ""
    @State private var showPlayerSelection = false
    @State private var showAlert = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Wrapping the main content in ScrollView.
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 20)
                        
                        Text("Roll Strike")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 40)
                        
                        Text("Sign in to Game Center for leaderboards & achievements, or continue as a guest.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        // No explicit line limit means text will wrap naturally.
                        
                        // Game Center Login Button
                        Button(action: {
                            print("GameCenter Login pressed")
                            if viewModel.isAuthenticated {
                                navigateToFlow = true
                            } else {
                                viewModel.performGameCenterLogin()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                Text("Login with Game Center")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading)
                        
                        // Last-used Player Login, if available.
                        if let lastPlayer = viewModel.selectedPlayer {
                            Button(action: {
                                print("Last Used Login pressed")
                                viewModel.selectedPlayer?.lastUsed = Date()
                                PlayerService.shared.addOrUpdatePlayer(viewModel.selectedPlayer!)
                                
                                if lastPlayer.type == .gameCenter,
                                    !viewModel.isAuthenticated {
                                    viewModel.performGameCenterLogin()
                                } else {
                                    navigateToFlow = true
                                }
                            }) {
                                Text("Login as \(lastPlayer.name)")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.secondaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .disabled(viewModel.isLoading)
                            
                            // If more than one player exists, allow selecting a different one.
                            if PlayerService.shared.players.count > 1 {
                                Button(action: {
                                    print("showPlayerSelection pressed")
                                    showPlayerSelection = true
                                }) {
                                    Text("Choose Existing Player")
                                        .font(.headline)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(AppTheme.secondaryColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                                .disabled(viewModel.isLoading)
                            }
                        }
                        
                        // New guest creation section.
                        VStack(spacing: 10) {
                            TextField("Enter Guest Name", text: $guestName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            Button(action: {
                                guard !guestName.isEmpty else {
                                    print("guestName is empty")
                                    return
                                }
                                print("continueAsGuest pressed")
                                viewModel.continueAsGuest(with: guestName)
                                navigateToFlow = true
                            }) {
                                Text("Create New Guest")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(guestName.isEmpty ? Color.black.opacity(0.5) : Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(guestName.isEmpty || viewModel.isLoading)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical)
                    // This ensures that even on a very small device the ScrollView can scroll.
                }
                .sheet(isPresented: $showPlayerSelection) {
                    PlayerSelectionView(players: PlayerService.shared.players) { selected in
                        viewModel.selectedPlayer = selected
                        showPlayerSelection = false
                        navigateToFlow = true
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Error"),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
                .onChange(of: viewModel.isAuthenticated, initial: false) { oldValue, newValue in
                    if newValue {
                        navigateToFlow = true
                    }
                }
                .onChange(of: viewModel.loginError, initial: false) { oldValue, newValue in
                    if let newValue {
                        alertMessage = newValue
                        showAlert = true
                    }
                }
                
                // Overlay Activity Indicator – blocks interactions.
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Logging in...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                }
            } // End of ZStack
        }
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(isPresented: $navigateToFlow) {
            MainMenuFlowView(loggedInPlayer: viewModel.selectedPlayer!)
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
