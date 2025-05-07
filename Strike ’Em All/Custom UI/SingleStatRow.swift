//
//  SingleStatRow.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import SwiftUI

struct SingleStatRow: View {
    let label: String, value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.accentColor)
            Spacer()
            Text(value).bold()
                .foregroundStyle(AppTheme.secondaryColor)
        }
    }
}
