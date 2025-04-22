//
//  PlayerSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import SwiftUI

struct PlayerSelectionView: View {
    @Environment(\.di) private var di
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var selectedPlayer: Player?
    
    @State private var showAddSheet = false
    @State private var localPlayers: [Player] = []
    
    private let onSelect: () -> Void
    
    init(
        selectedPlayer: Binding<Player?>,
        onSelect: @escaping () -> Void
    ) {
        self._selectedPlayer = selectedPlayer
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(localPlayers, id: \.id) { player in
                    Button {
                        selectedPlayer = player
                        di.playerRepo.save(player)  // update lastUsed
                        onSelect()
                        dismiss()
                    } label: {
                        HStack {
                            Text(player.name)
                            Spacer()
                            if selectedPlayer?.id == player.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                    }
                }
                .onDelete(perform: deletePlayers)
            }
            .navigationTitle("Select Player")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add New Player")
                }
            }
            .onAppear {
                localPlayers = di.playerRepo.playersSubject.value  // sync
            }
            .sheet(isPresented: $showAddSheet) {
                AddPlayerView { newName in
                    let newPlayer = Player(name: newName, type: .guest, lastUsed: Date())
                    di.playerRepo.save(newPlayer)
                    localPlayers = di.playerRepo.playersSubject.value
                    selectedPlayer = newPlayer
                    showAddSheet = false
                    dismiss()
                }
            }
        }
    }
    
    private func deletePlayers(at offsets: IndexSet) {
        for idx in offsets { di.playerRepo.delete(localPlayers[idx]) }
        localPlayers.remove(atOffsets: offsets)
    }
}

struct AddPlayerView: View {
    @State private var name = ""
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Player Name", text: $name)
                    .disableAutocorrection(true)
            }
            .navigationTitle("New Player")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(name)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
