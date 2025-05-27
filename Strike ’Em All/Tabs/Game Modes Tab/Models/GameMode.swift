//
//  GameMode.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/25/25.
//

import Foundation

enum GameMode: String, CaseIterable, Identifiable {
  case classic
  case dartboard
  case persisting
  case multiCircle

  var id: String { rawValue }

  /// Display title
  var title: String {
    switch self {
    case .classic:      return "Classic Rows"
    case .dartboard:    return "Circular Dartboard"
    case .persisting:   return "Persisting Balls"
    case .multiCircle:  return "Multi-Circle Darts"
    }
  }

  /// Longer description
  var description: String {
    switch self {
    case .classic:
      return "Horizontal rows. Launch at one row at a time, score if you hit the active cell."
    case .dartboard:
      return "Concentric rings—closer to center means higher multiplier."
    case .persisting:
      return "Balls stick around and bounce off each other. End-of-game scoring by density."
    case .multiCircle:
      return "Each ring has a fixed point value. Sum your points after N balls per player."
    }
  }
    
    var symbolName: String {
        switch self {
        case .classic:     return "rectangle.stack"
        case .dartboard:   return "target"
        case .persisting:  return "circle.grid.3x3.fill"
        case .multiCircle: return "circle.hexagonpath"
        }
    }
}
