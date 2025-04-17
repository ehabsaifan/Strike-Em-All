//
//  PlayerSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import SwiftUI

struct PlayerSelectionView: View {
    @State private var players: [Player]
    @State private var showAddSheet = false
    var onSelect: (Player) -> Void
    @Environment(\.dismiss) private var dismiss

    init(players: [Player], onSelect: @escaping (Player) -> Void) {
        self._players = State(initialValue: players)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(players, id: \.id) { player in
                    Button(player.name) {
                        onSelect(player)
                        dismiss()
                    }
                }
                .onDelete(perform: deletePlayers)
            }
            .navigationTitle("Select Player")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add New Player")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPlayerView { newName in
                    let newPlayer = Player(name: newName, type: .guest, lastUsed: Date())
                    PlayerService.shared.addOrUpdatePlayer(newPlayer)
                    players.append(newPlayer)  // Refresh local list turn0search2
                    onSelect(newPlayer)
                    showAddSheet = false
                    dismiss()
                }
            }
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        offsets.forEach { idx in
            let p = players[idx]
            PlayerService.shared.deletePlayer(p)
        }
        players.remove(atOffsets: offsets)
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
        .scrollDismissesKeyboard(.interactively)  // Good UX for forms turn1search2
    }
}
