//
//  PlayerSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import SwiftUI

struct PlayerSelectionView: View {
    @State private var players: [Player]
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
                    Button(action: {
                        onSelect(player)
                        dismiss()
                    }) {
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text(player.type.rawValue.capitalized)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deletePlayers)
            }
            .navigationTitle("Select Player")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        for index in offsets {
            let player = players[index]
            PlayerService.shared.deletePlayer(player)
        }
        players.remove(atOffsets: offsets)
    }
}
