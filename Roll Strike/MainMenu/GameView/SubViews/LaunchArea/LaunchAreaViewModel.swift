//
//  LaunchAreaViewModel.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/29/25.
//

import SwiftUI

class LaunchAreaViewModel: ObservableObject {
    // Bindings for the UI.
    @Published var dragOffset: CGSize = .zero
    @Published var launchImpulse: CGVector? = nil
        
    let pullStrength: CGFloat = 7
    let launchAreaHeight: CGFloat
    let ballDiameter: CGFloat
    
    var screenWidth: CGFloat {
         GameViewModel.screenWidth
    }
    
    init(launchAreaHeight: CGFloat, ballDiameter: CGFloat) {
        self.launchAreaHeight = launchAreaHeight
        self.ballDiameter = ballDiameter
    }
    
    /// For a human pull, the UI updates `dragOffset` and on release sets `launchImpulse`.
    /// For computer simulation, we generate a random drag offset and compute an impulse.
    func simulateComputerPull(completion: @escaping () -> Void) {
        print("simulateComputerPull")
        // Generate a random drag offset simulating a pull.
        // Adjust ranges to taste.
        let randomWidth = CGFloat.random(in: -50...50)
        let randomHeight = CGFloat.random(in: -90...(-2))
        let simulatedOffset = CGSize(width: randomWidth, height: -randomHeight)
        
        self.dragOffset = simulatedOffset
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let pullStrength: CGFloat = 7
            let force = CGVector(
                dx: -simulatedOffset.width * pullStrength,
                dy: simulatedOffset.height * pullStrength
            )
            self.launchImpulse = force
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                self.dragOffset = .zero
            }
            completion()
        }
    }
}
