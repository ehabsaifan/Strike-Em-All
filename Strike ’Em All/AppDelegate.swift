//
//  AppDelegate.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/4/25.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupTabBar()
        return true
    }
    private func setupTabBar() {
        // Configure UITabBar to your brand colors
                let tabAppearance = UITabBarAppearance()
                tabAppearance.configureWithOpaqueBackground()
                tabAppearance.backgroundColor = UIColor(AppTheme.primaryColor)

                // Selected state (icon + title)
                tabAppearance.stackedLayoutAppearance.selected.iconColor =
                    UIColor(AppTheme.accentColor)
                tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor(AppTheme.accentColor)
                ]

                // Unselected state
                tabAppearance.stackedLayoutAppearance.normal.iconColor =
                    UIColor(AppTheme.tertiaryColor)
                tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor(AppTheme.tertiaryColor)
                ]

                // Apply globally
                UITabBar.appearance().standardAppearance = tabAppearance
                if #available(iOS 15, *) {
                    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
                }

    }
}

