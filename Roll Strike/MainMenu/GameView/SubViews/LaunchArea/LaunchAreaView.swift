//
//  LaunchAreaView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/23/25.
//

import SwiftUI

struct LaunchAreaView: View {
    @ObservedObject var viewModel: LaunchAreaViewModel
    
    var body: some View {
        ZStack {
            // Background for the launch area.
            Rectangle()
                .fill(Color.clear)
                .ignoresSafeArea(edges: .bottom)
            GeometryReader { geo in
                let leftPin = CGPoint(x: viewModel.screenWidth * 0.3, y: viewModel.ballDiameter)
                let rightPin = CGPoint(x: viewModel.screenWidth * 0.7, y: viewModel.ballDiameter)
                
                // Compute the current ball center based on the drag offset.
                let currentBallCenter = CGPoint(
                    x: viewModel.screenWidth / 2 + viewModel.dragOffset.width,
                    y: viewModel.ballDiameter + viewModel.dragOffset.height
                )
                
                ZStack {
                    // Draw the elastic string with a rope-like texture.
                    Path { path in
                        path.move(to: leftPin)
                        path.addLine(to: currentBallCenter)
                        path.addLine(to: rightPin)
                    }
                    .stroke(
                        ImagePaint(image: Image("rope"), scale: 0.5),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    
                    Image("screw_head")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .position(leftPin)
                    
                    Image("screw_head")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .position(rightPin)
                }
                .background(AppTheme.primaryColor)                
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dragOffset = CGSize(width: value.translation.width,
                                            height: value.translation.height)
                    viewModel.dragOffset = dragOffset
                }
                .onEnded { value in
                    let force = CGVector(
                        dx: -value.translation.width * viewModel.pullStrength,
                        dy: value.translation.height * viewModel.pullStrength
                    )
                    viewModel.launchImpulse = force
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        viewModel.dragOffset = .zero
                    }
                }
        )
    }
}
