//
//  PlayerNameView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/1/25.
//

import SwiftUI

struct PlayerNameView: View {
    let name: String
    let isActive: Bool
    
    var body: some View {
        Text(name)
            .font(.system(size: 16, weight: .medium))
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(isActive ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color(.systemGray5) : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .animation(nil, value: isActive)
    }
}
