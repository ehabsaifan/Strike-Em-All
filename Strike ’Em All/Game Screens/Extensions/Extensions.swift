//
//  Extensions.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/25/25.
//

import SwiftUI
import UIKit

extension TimeInterval {
    /// Formats a time interval as `mm:ss` or `hh:mm:ss` depending on `alwaysShowHours`
    /// - Parameter alwaysShowHours: if true, always output `hh:mm:ss`; if false, only include hours when >= 1 hour
    /// - Returns: a localized, zero-padded string
    func formattedTime(alwaysShowHours: Bool = false) -> String {
        let formatter = DateComponentsFormatter()
        // positional style gives "01:02:03" rather than "1h 2m 3s"
        formatter.unitsStyle = .positional
        // pad to 2 digits each field
        formatter.zeroFormattingBehavior = .pad
        
        // choose which components
        if alwaysShowHours {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = self >= 3600
                ? [.hour, .minute, .second]
                : [.minute, .second]
        }
        
        // DateComponentsFormatter automatically localizes separators and order
        return formatter.string(from: self) ?? "00:00"
    }
}

extension UIImage: @retroactive Identifiable {
    
}

extension UIView {
    func snapshotImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
          layer.render(in: ctx.cgContext)
        }
      }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
    
    @MainActor
    func snapshot() -> UIImage? {
        let targetSize = UIScreen.main.bounds
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(targetSize.size)
        return renderer.uiImage
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
