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
    @Binding var selectedBallType: RollingObjectType {
        didSet {
            selectedIndex = ballTypes.firstIndex(of: selectedBallType) ?? 0
        }
    }
    
    // Use a state variable to drive the custom segmented control.
    @State private var selectedIndex: Int = 0
    
    let settings: RollingObjectCarouselSettings
    
    // Closure to notify when selection is done.
    var onSelectionDone: () -> Void
    
    // A helper array mapping indices to ball types.
    private var ballTypes: [RollingObjectType] {
        RollingObjectType.allCases
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Custom segmented control replacing the Picker.
            CustomSegmentedControl(selectedSegment: $selectedIndex, items: ballTypes.map { $0.rawValue }, settings: settings.segmentSettings)
                .onChange(of: selectedIndex) { newIndex in
                    selectedBallType = ballTypes[newIndex]
                    onSelectionDone()
                }
            
            // A horizontal scrolling list of ball images (optional if you want both controls).
            HStack {
                ForEach(ballTypes, id: \.self) { type in
                    Image(type.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .frame(maxWidth: .infinity)
                        .padding(.all)
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedBallType == type ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedBallType = type
                            withAnimation {
                                onSelectionDone()
                            }
                        }
                }
            }
            .padding(.all)
        }
        .cornerRadius(8)
        .background(settings.backGroundColor.opacity(0.8))
    }
}
