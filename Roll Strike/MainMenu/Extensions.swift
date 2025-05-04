//
//  Extensions.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/25/25.
//

import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

extension UIApplication {
    var rootVC: UIViewController? {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("⚠️ Unable to find rootViewController to present Game Center")
            return nil
        }
        return rootVC
    }

    /// Returns the top-most view controller from the keyWindow's rootViewController.
    static func topViewController(_ base: UIViewController? = UIApplication.shared.rootVC) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(selected)
        } else if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }

    var keyWindow: UIWindow? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

protocol ClassNameRepresentable {
    var className: String { get }
}

extension ClassNameRepresentable {
    var className: String {
        return String(describing: Self.self)
    }
}
