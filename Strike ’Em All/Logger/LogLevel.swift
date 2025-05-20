//
//  LogLevel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/14/25.
//

import Foundation

enum LogLevel: Int, Comparable, Codable, CustomStringConvertible {
    case verbose = 0, debug, info, warning, error

    var label: String {
        switch self {
        case .verbose: return "🟣VERBOSE"
        case .debug:   return "🟢DEBUG"
        case .info:    return "🟡INFO"
        case .warning: return "🟠WARN"
        case .error:   return "🔴ERROR"
        }
    }
    
    var description: String {
        return label
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
