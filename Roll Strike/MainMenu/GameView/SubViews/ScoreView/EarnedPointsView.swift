//
//  EarnedPointsView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/9/25.
//

import SwiftUI

struct EarnedPointsView: View {
    let text: String
    let finalOffset: CGSize

    @State private var offset: CGSize

    init(text: String, startOffset: CGSize = .zero, finalOffset: CGSize = CGSize(width: 30, height: -UIScreen.main.bounds.height / 3)) {
        self.text = text
        self.finalOffset = finalOffset
        _offset = State(initialValue: startOffset)
    }

    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(.white)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange)
                    .shadow(radius: 5)
            )
            .offset(offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    offset = finalOffset
                }
            }
            .transition(.scale.combined(with: .opacity))
    }
}
