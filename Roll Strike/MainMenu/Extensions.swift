//
//  Extensions.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/25/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
