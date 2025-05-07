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
                // Display the cell content: an image or text.
                if let imageName = content.imageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: w * 0.8, height: h * 0.8)
                } else {
                    Text(content.text)
                        .font(.system(size: min(w, h) * 0.5))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(width: w * 0.8, height: h * 0.8, alignment: .center)
                        .foregroundColor(.black)
                }
                
                // Animate the marking overlay when marking state changes
                if marking != .none {
                    MarkingOverlay(marking: marking)
                        .frame(width: w, height: h)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: marking)
                }
            }
        }
    }
}

struct MarkingOverlay: View {
    let marking: MarkingState
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            if marking == .half {
                // Single diagonal for half marking
                Path { path in
                    path.move(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: h))
                }
                .stroke(Color.red, lineWidth: 2)
                .opacity(0.5)
            } else if marking == .complete {
                // Two diagonals for complete marking
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: w, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: h))
                    }
                    .stroke(Color.red, lineWidth: 2)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: w, y: h))
                    }
                    .stroke(Color.red, lineWidth: 2)
                }
            }
        }
    }
}

struct GameCellView_Previews: PreviewProvider {
    static var previews: some View {
        GameCellView(marking: .half,
                     content: GameContent(text: "Apple"))
        .frame(width: 70, height: 70)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
