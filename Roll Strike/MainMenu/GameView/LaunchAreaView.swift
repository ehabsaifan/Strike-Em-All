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
    
    let launchAreaHeight: CGFloat
    let ballDiameter: CGFloat

    var restingBallCenterY: CGFloat {
        -GameViewModel.bottomSafeAreaInset + launchAreaHeight - ballDiameter / 2
    }
    
    var body: some View {
        ZStack {
            // Brown background for the slingshot area
            Rectangle()
                .fill(Color.clear)
                .ignoresSafeArea(edges: .bottom)
            
            GeometryReader { geo in
                let width = geo.size.width
                // Pins at 30% and 70% of width, aligned at restingBallCenterY
                let leftPin = CGPoint(x: width * 0.3, y: restingBallCenterY)
                let rightPin = CGPoint(x: width * 0.7, y: restingBallCenterY)
                
                // The ball's center is offset by dragOffset
                let currentBallCenter = CGPoint(
                    x: width / 2 + dragOffset.width,
                    y: restingBallCenterY - dragOffset.height
                )
                
                ZStack {
                    // 1) Draw rope path with texture
                    Path { path in
                        path.move(to: leftPin)
                        path.addLine(to: currentBallCenter)
                        path.addLine(to: rightPin)
                    }
                    .stroke(
                        ImagePaint(
                            image: Image("rope"), // Your rope texture
                            scale: 0.5
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    
                    // 2) Place nail images at each pin
                    Image("screw_head")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .position(leftPin)
                    
                    Image("screw_head")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .position(rightPin)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = CGSize(
                        width: value.translation.width,
                        height: -value.translation.height
                    )
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
