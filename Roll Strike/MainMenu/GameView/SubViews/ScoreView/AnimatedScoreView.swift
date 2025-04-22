//
//  AnimatedScoreView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/10/25.
//

import SwiftUI

struct AnimatedScoreView: View {
    let startingScore: Int
    let finalScore: Int

    @State private var animatingScore: Double = 0

    var body: some View {
        Color.clear
            .countUp(to: animatingScore)
            .onAppear {
                animatingScore = Double(startingScore)
                withAnimation(.easeOut(duration: 0.5)) {
                    animatingScore = Double(finalScore)
                }
            }
            .onChange(of: finalScore, initial: false) { _, newFinalScore in
                animatingScore = Double(startingScore)
                withAnimation(.easeOut(duration: 0.5)) {
                    animatingScore = Double(newFinalScore)
                }
            }
    }
}
