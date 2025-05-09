//
//  SmallActionButton.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/30/25.
//

import SwiftUI

struct SmallActionButton: View {
    let title: String
    let icon: String?  // not used, but kept for signature matching
    let color: Color
    let action: () -> Void
   
    init(title: String,
         icon: String?,
         color: Color,
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: 24)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .controlSize(.regular)
        .cornerRadius(6)
    }
}
