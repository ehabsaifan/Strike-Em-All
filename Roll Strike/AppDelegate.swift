//
//  AppDelegate.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/4/25.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = PlayerService.shared
        return true
    }
}

