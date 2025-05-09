//
//  DashedDivider.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import SwiftUI

struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw exactly one line across the middle of the available rect
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct DashedDivider: View {
    var color: Color           = Color(UIColor.separator)
    var dash: [CGFloat]        = [5, 3]
    var lineWidth: CGFloat     = 1
    
    var body: some View {
        HorizontalLine()
          .stroke(style: StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .butt,
            dash: dash
          ))
          .foregroundColor(color)
          .frame(height: lineWidth)
    }
}
