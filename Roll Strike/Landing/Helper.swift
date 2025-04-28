//
//  Helper.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/23/25.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(_DismissKeyboard())
    }
}

private struct _DismissKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
          .background(
            Color.clear
              .contentShape(Rectangle())
              .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
          )
    }
}
#endif
