//
//  SectionBlock.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/30/25.
//

import SwiftUI

struct SectionBlock<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .foregroundColor(AppTheme.secondaryColor)
                .cornerRadius(6)
            Divider()
                .padding(.bottom, 4)
                .padding(.horizontal)
            content()
                .padding(.horizontal)
            
            Spacer()
                .frame(height: 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
