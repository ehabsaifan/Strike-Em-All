//
//  VolumeControlView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/9/25.
//

import SwiftUI

struct VolumeControlView: View {
    @Binding var volume: Float  // Volume is 0.0...1.0
    
    var body: some View {
        VStack {
            Text("Volume")
                .font(.headline)
                .foregroundColor(.white)
            Slider(value: $volume, in: 0...1)
                .accentColor(AppTheme.secondaryColor)
            HStack {
                Text("Mute")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text("Max")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(AppTheme.primaryColor)
        .cornerRadius(12)
    }
}
