//
//  RollStrikeApp.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/5/25.
//

import SwiftUI

@main
struct RollStrikeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            LandingView() // This should be your main screen
        }
    }
}
