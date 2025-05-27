//
//  AppMetadata.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/14/25.
//

import UIKit

struct AppMetadata: Codable {
    let uuid: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let createdAt: Date
    
    init(uuid: String = UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
         deviceModel: String = UIDevice.current.model,
         osVersion: String = UIDevice.current.systemVersion,
         appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?.?",
         buildnumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–",
         createdAt: Date = Date()) {
        self.uuid = uuid
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.buildNumber = buildnumber
        self.createdAt = createdAt
    }
}
