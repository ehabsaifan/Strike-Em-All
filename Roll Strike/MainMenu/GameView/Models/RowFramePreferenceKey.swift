//
//  RowFramePreferenceKey.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/10/25.
//

import SwiftUI

struct RowFramePreferenceKey: PreferenceKey {
    typealias Value = [Int: CGRect]
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
