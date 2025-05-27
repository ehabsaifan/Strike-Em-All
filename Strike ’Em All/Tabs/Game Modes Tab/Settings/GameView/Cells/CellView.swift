//
//  CellView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

struct GameCellView: View {
    let marking: MarkingState
    let content: GameContent

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // 1) Content at the back
                if let imageName = content.imageName,
                   let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: w * 0.8, height: h * 0.8)
                } else {
                    Text(content.text)
                        .font(.system(size: min(w,h) * 0.5))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(width: w * 0.8, height: h * 0.8)
                        .foregroundColor(.black)
                }

                // 2) Overlay on top when marked
                if marking != .none {
                    MarkingOverlay(marking: marking)
                        .frame(width: w, height: h)
                        // animate any change in `marking`
                        .animation(.easeInOut(duration: 0.3), value: marking)
                }
            }
        }
    }
}

struct MarkingOverlay: View {
    let marking: MarkingState

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            switch marking {
            case .none:
                EmptyView()

            case .half:
                // Single diagonal slash
                Path { path in
                    path.move(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: h))
                }
                .stroke(AppTheme.accentColor, lineWidth: 3)
                .opacity(0.6)

            case .complete:
                // Centered stamp
                StampOverlay()
                    .frame(width: w,
                           height: h)
                    .position(x: w/2, y: h/2)
            }
        }
    }
}

struct StampOverlay: View {
    @State private var scale: CGFloat = 0.1
    let color: Color = AppTheme.accentColor

    var body: some View {
        Image(systemName: "checkmark.circle")
          .resizable()
          .aspectRatio(1, contentMode: .fit)
          .foregroundColor(color)
          .background(.black.opacity(0.4))
          .cornerRadius(4)
          .scaleEffect(scale)
          .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
              scale = 1.0
            }
          }
    }
}
