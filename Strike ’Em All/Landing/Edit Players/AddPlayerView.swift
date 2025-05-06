//
//  AddPlayerView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI

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
