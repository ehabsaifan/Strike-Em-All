//
//  Achievement.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import Foundation

struct Achievement: Codable, Identifiable {
  let id: String                              // e.g. “firstWin”, “5Wins”
  let title: String                           // e.g. “First Win”
  let preEarnedDesc: String                   // before unlocking
  let earnedDesc: String                      // after unlocking
  let badgeImageName: String                  // your asset name
  var isEarned: Bool                          // true once claimed
  var dateEarned: Date?                       // when it was claimed
}
