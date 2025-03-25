//
//  LaunchAreaView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/23/25.
//

import SwiftUI

struct LaunchAreaView: View {
    @Binding var launchImpulse: CGVector?
    @Binding var dragOffset: CGSize
    
    // These come from the view model.
    let launchAreaHeight: CGFloat
    let ballDiameter: CGFloat

    var restingBallCenterY: CGFloat {
        -GameViewModel.bottomSafeAreaInset + launchAreaHeight - ballDiameter / 2
    }
    
    var body: some View {
        ZStack {
            // Background for the launch area.
            Rectangle()
                .fill(Color.brown)
                .ignoresSafeArea(edges: .bottom)
            
            GeometryReader { geo in
                let width = geo.size.width
                
                // Define fixed positions for the left and right pins.
                let leftPin = CGPoint(x: width * 0.3, y: restingBallCenterY)
                let rightPin = CGPoint(x: width * 0.7, y: restingBallCenterY)
                
                // Compute the ball's current center based on the drag offset.
                let currentBallCenter = CGPoint(
                    x: width / 2 + dragOffset.width,
                    y: restingBallCenterY - dragOffset.height
                )
                
                // Draw the elastic string.
                Path { path in
                    path.move(to: leftPin)
                    path.addLine(to: currentBallCenter)
                    path.addLine(to: rightPin)
                }
                .stroke(Color.black, lineWidth: 3)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = CGSize(width: value.translation.width, height: -value.translation.height)
                }
                .onEnded { value in
                    let pullStrength: CGFloat = 7
                    let force = CGVector(
                        dx: -value.translation.width * pullStrength,
                        dy: value.translation.height * pullStrength
                    )
                    launchImpulse = force
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        dragOffset = .zero
                    }
                }
        )
    }
}
