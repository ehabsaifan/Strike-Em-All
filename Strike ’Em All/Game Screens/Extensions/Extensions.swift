//
//  Extensions.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/25/25.
//

import SwiftUI
import UIKit
import CryptoKit

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
    
    func mailSheet<Content: View>(
        isPresented: Binding<Bool>,
        onCannotSend: @escaping ()->Void,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .sheet(isPresented: isPresented, content: content)
            .onChange(of: isPresented.wrappedValue) { _, _ in
                if isPresented.wrappedValue && !ComposeMailView.canSendMail() {
                    onCannotSend()
                }
            }
    }
}

extension UIApplication {
    var rootVC: UIViewController? {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            FileLogger.shared.log("Unable to find rootViewController", level: .error)
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

extension String {
  /// Base64‐URL encode (no “=”, “+”, “/” → “-” “_”)
    var ckRecordNameSafe: String {
        // 1️⃣ hash
        let digest = Insecure.MD5.hash(data: Data(self.utf8))
        let bytes  = Data(digest)             // 16 bytes

        // 2️⃣ Base64‐URL encode and trim “=”
        return bytes.base64EncodedString()
          .replacingOccurrences(of: "+", with: "-")
          .replacingOccurrences(of: "/", with: "_")
          .trimmingCharacters(in: CharacterSet(charactersIn: "="))
      }
}

extension FileManager {
  static var analyticsDir: URL {
    let docs = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
    let dir  = docs.appendingPathComponent("Analytics", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir,
                                            withIntermediateDirectories: true)
    return dir
  }
    
  static var playersDir: URL {
    let docs = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
    let dir  = docs.appendingPathComponent("Players", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir,
                                            withIntermediateDirectories: true)
    return dir
  }
}
