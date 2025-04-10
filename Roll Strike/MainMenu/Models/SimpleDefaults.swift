//
//  SimpleDefaults.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/9/25.
//

import Foundation

struct SimpleDefaults {
    enum Key: String {
        case volumePref = "volumePreference"
        case numberOfRows
    }
    
    static func setValue<T>(_ value: T, forKey key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    /// Retrieve the value for the specified key, or return a default value if not found.
    static func getValue<T>(forKey key: Key, defaultValue: T) -> T {
        return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
    }
}
