//
//  BallSelectionView.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/1/25.
//

import SwiftUI

struct RollingObjectCarouselView: View {
    @Binding var selectedBallType: RollingObjectType
    // Closure to notify when selection is done.
    var onSelectionDone: () -> Void
    
    // Use a state variable to drive the custom segmented control.
    @State private var selectedIndex: Int = 0
    
    // A helper array mapping indices to ball types.
    private var ballTypes: [RollingObjectType] {
        RollingObjectType.allCases
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // Custom segmented control replacing the Picker.
            CustomSegmentedControl(selectedSegment: $selectedIndex, items: ballTypes.map { $0.rawValue }, selectedTintColor: .yellow, normalTextColor: .white, selectedTextColor: .black)
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
                            // Update both the index and the selected ball type.
                            if let index = ballTypes.firstIndex(of: type) {
                                selectedIndex = index
                            }
                            selectedBallType = type
                            withAnimation {
                                onSelectionDone()
                            }
                        }
                }
            }
            .padding(.all)
        }
        .background(Color.orange.opacity(0.8))
    }
}
