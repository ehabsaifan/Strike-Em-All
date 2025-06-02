//
//  SimpleDefaults.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/9/25.
//

import Foundation

struct SimpleDefaults {
    enum Key {
        case volumePref
        case numberOfRows
        case numberOfBalls
        case savedPlayers
        case rollingObject
        case achievements(String)
        case loggingEnabled
        case loggingLevel
        
        var keyString: String {
            switch self {
            case .volumePref:
                return "volumePreference"
            case .achievements(let string):
                return string
            default:
                return "\(self)"
            }
        }
    }
    
    static func setValue<T>(_ value: T, forKey key: Key) {
        UserDefaults.standard.set(value, forKey: key.keyString)
    }
    
    /// Retrieve the value for the specified key, or return a default value if not found.
    static func getValue<T>(forKey key: Key) -> T? {
        return UserDefaults.standard.object(forKey: key.keyString) as? T
    }
    
    static func setEnum<T: Encodable>(_ value: T, forKey key: Key) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key.keyString)
    }
    
    static func getEnum<T: Decodable>(forKey key: Key) -> T? {
        guard let data = UserDefaults.standard.object(forKey: key.keyString) as? Data else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
