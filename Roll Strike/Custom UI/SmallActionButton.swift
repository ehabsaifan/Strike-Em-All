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
    let buttonStyle: any PrimitiveButtonStyle
    let action: () -> Void
   
    init(title: String,
         icon: String?,
         color: Color,
         buttonStyle: any PrimitiveButtonStyle = .bordered,
         action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.buttonStyle = buttonStyle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .controlSize(.regular)
        .cornerRadius(6)
    }
}
