//
//  BallSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/1/25.
//

import SwiftUI

struct RollingObjectCarouselSettings {
    let segmentSettings: CustomSegmentedControlSettings
    let backGroundColor: Color
    
    init(segmentSettings: CustomSegmentedControlSettings = CustomSegmentedControlSettings(),
         backGroundColor: Color = .white) {
        self.segmentSettings = segmentSettings
        self.backGroundColor = backGroundColor
    }
}

struct RollingObjectCarouselView: View {
    @Binding var selectedBallType: RollingObjectType
    
    let settings: RollingObjectCarouselSettings
    var onSelectionDone: () -> Void
    
    private var ballTypes: [RollingObjectType] { RollingObjectType.allCases }
    
    init(selectedBallType: Binding<RollingObjectType>,
         settings: RollingObjectCarouselSettings = .init(),
         onSelectionDone: @escaping () -> Void)
    {
        self._selectedBallType = selectedBallType
        self.settings = settings
        self.onSelectionDone = onSelectionDone
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ballTypes, id: \.self) { type in
                VStack {
                    Text(type.rawValue)
                        .font(.caption)
                        .foregroundStyle(selectedBallType == type ? Color(settings.segmentSettings.selectedTextColor):
                                            Color(settings.segmentSettings.normalTextColor))
                    Image(type.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedBallType == type ?
                                        AppTheme.secondaryColor: Color.clear, lineWidth: 2)
                            
                        )
                        .onTapGesture {
                            selectedBallType = type
                            onSelectionDone()
                        }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(settings.backGroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
