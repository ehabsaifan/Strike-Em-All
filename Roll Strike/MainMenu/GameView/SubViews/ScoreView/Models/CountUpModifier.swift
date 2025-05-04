//
//  CountUpModifier.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/10/25.
//

import SwiftUI

struct CountUpModifier: AnimatableModifier {
    var number: Double

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        content.overlay(
            Text("\(Int(number))")
                .font(.headline)
                .foregroundColor(AppTheme.secondaryColor)
                .fixedSize()
        )
        .fixedSize() 
    }
}

extension View {
    func countUp(to number: Double) -> some View {
        self.modifier(CountUpModifier(number: number))
    }
}

