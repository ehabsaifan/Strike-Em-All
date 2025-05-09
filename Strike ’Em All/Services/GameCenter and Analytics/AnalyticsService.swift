//
//  AnalyticsService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/13/25.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

protocol AnalyticsServiceProtocol {
    var analyticsPublisher: CurrentValueSubject<GameAnalytics, Never> { get }
    
    func updateAnalytics(correctShots: Int, missedShots: Int, didWin: Bool, finalScore: Int, gameTimePlayed: Double)
    func loadAnalytics(completion: @escaping (Result<GameAnalytics, Error>) -> Void)
    func saveAnalytics(completion: @escaping (Result<Void, Error>) -> Void)
}

final class AnalyticsService: ObservableObject {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordID: CKRecord.ID
    private let defaultsKey: SimpleDefaults.Key
    private let recordType = "GameAnalytics"
    
    @Published private(set) var analytics: GameAnalytics {
        didSet {
            analyticsPublisher.send(analytics)
        }
    }
    
    /// The single, authoritative subject for analytics updates
    let analyticsPublisher: CurrentValueSubject<GameAnalytics, Never>
    
    init(recordName: String) {
        self.recordID    = CKRecord.ID(recordName: recordName)
        self.defaultsKey = .gameAnalyticsData(recordName)
        self.container   = CKContainer.default()
        self.database    = container.privateCloudDatabase
        
        // Seed initial value
        let initial = Self.loadFromUserDefaults(forKey: defaultsKey)
        ?? GameAnalytics()
        
        self.analytics          = initial
        self.analyticsPublisher = CurrentValueSubject(initial)
        
        // Load from CloudKit
        loadAnalytics { [weak self] result in
            guard let self = self else { return }
                switch result {
                case .success(let loaded):
                    self.analytics = loaded
                    print("CloudKit load analytics success")
                    Self.saveToUserDefaults(loaded, forKey: self.defaultsKey)
                    self.saveAchievementsIfNeeded(loaded)
                case .failure(let error):
                    print("CloudKit load analytics error: \(error.localizedDescription)")
                }
        }
    }
    
    func saveAchievementsIfNeeded(_ analytics: GameAnalytics) {
        var new = analytics
        let achievements = getAchievements(analytics)
        
        if new.achievementEarnedIDs != achievements.ids ||
            new.achievementEarnedDates != achievements.dates {
            
            new.achievementEarnedIDs   = achievements.ids
            new.achievementEarnedDates = achievements.dates
            
            Self.saveToUserDefaults(new, forKey: defaultsKey)
            
                self.analytics = new
            
            saveAnalytics { result in
                switch result {
                case .success():
                    print("Analytics successfully saved to CloudKit.")
                case .failure(let error):
                    print("Error saving analytics: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getAchievements(_ analytics: GameAnalytics)
    -> (dates: [Date], ids: [String])
    {
        let obtained = GameCenterAchievment.getAchievementsObtained(
            for: analytics.lifetimeTotalScore,
            analytics: analytics
        )
        
        let existingIDs = Set(analytics.achievementEarnedIDs)
        var newIDs = Set<String>()
        
        obtained.forEach { ach in
            if !existingIDs.contains(ach.rawValue) {
                newIDs.insert(ach.rawValue)
            }
        }
        
        let combinedIDs   = analytics.achievementEarnedIDs + Array(newIDs)
        let combinedDates = analytics.achievementEarnedDates
        + Array(repeating: Date(), count: newIDs.count)
        
        return (dates: combinedDates, ids: combinedIDs)
    }
    
    // MARK: - Offline Persistence Helpers
    
    private static func loadFromUserDefaults(
        forKey key: SimpleDefaults.Key
    ) -> GameAnalytics? {
        guard
            let data: Data = SimpleDefaults.getValue(forKey: key),
            let decoded = try? JSONDecoder().decode(GameAnalytics.self, from: data)
        else {
            return nil
        }
        return decoded
    }
    
    private static func saveToUserDefaults(
        _ analytics: GameAnalytics,
        forKey key: SimpleDefaults.Key
    ) {
        if let data = try? JSONEncoder().encode(analytics) {
            SimpleDefaults.setValue(data, forKey: key)
        }
    }
}

// MARK: - AnalyticsServiceProtocol

extension AnalyticsService: AnalyticsServiceProtocol {
    /// Asynchronously load analytics from CloudKit.
    func loadAnalytics(
        completion: @escaping (Result<GameAnalytics, Error>) -> Void
    ) {
        database.fetch(withRecordID: recordID) { record, error in
        let result: Result<GameAnalytics, Error>
            if let error = error {
                result = .failure(error)
            } else if let record = record {
                let loaded = GameAnalytics(
                    lifetimeTotalScore:                   record["lifetimeTotalScore"]                as? Int    ?? 0,
                    lifetimeTotalTimePlayed:             record["lifetimeTotalTimePlayed"]          as? Double ?? 0,
                    lifetimeCorrectShots:                 record["lifetimeCorrectShots"]             as? Int    ?? 0,
                    lifetimeMissedShots:                  record["lifetimeMissedShots"]              as? Int    ?? 0,
                    lifetimeWinnings:                     record["lifetimeWinnings"]                 as? Int    ?? 0,
                    lifetimeGamesPlayed:                  record["lifetimeGamesPlayed"]              as? Int    ?? 0,
                    lifetimeLongestWinningStreak:         record["lifetimeLongestWinningStreak"]     as? Int    ?? 0,
                    currentWinningStreak:                 record["currentWinningStreak"]             as? Int    ?? 0,
                    lastGameCorrectShots:                 record["lastGameCorrectShots"]             as? Int    ?? 0,
                    lastGameMissedShots:                  record["lastGameMissedShots"]              as? Int    ?? 0,
                    lifetimePerfectGamesCount:            record["lifetimePerfectGamesCount"]        as? Int    ?? 0,
                    lifetimeLongestPerfectGamesStreak:    record["lifetimeLongestPerfectGamesStreak"]as? Int    ?? 0,
                    achievementEarnedIDs:                 record["achievementEarnedIDs"]             as? [String] ?? [],
                    achievementEarnedDates:               record["achievementEarnedDates"]           as? [Date]  ?? []
                )
                result = .success(loaded)
            } else {
                result = .success(GameAnalytics())
            }
            DispatchQueue.main.async {
                    completion(result)
            }
        }
    }
    
    /// Update analytics on the main queue, then persist.
    func updateAnalytics(
        correctShots: Int,
        missedShots: Int,
        didWin: Bool,
        finalScore: Int,
        gameTimePlayed: Double
    ) {
        var updated = self.analytics
        print("correctShots \(correctShots) | missedShots \(missedShots)")
        // Update lifetime metrics
        updated.lifetimeTotalScore       += finalScore
        updated.lifetimeGamesPlayed      += 1
        updated.lastGameCorrectShots      = correctShots
        updated.lastGameMissedShots       = missedShots
        updated.lifetimeCorrectShots     += correctShots
        updated.lifetimeMissedShots      += missedShots
        updated.lifetimeTotalTimePlayed  += gameTimePlayed
        
        print("updateAnalytics with the new values \(analytics)")
        
        // Perfect games
        if missedShots == 0 {
            updated.lifetimePerfectGamesCount += 1
            self.analytics.lifetimeLongestPerfectGamesStreak += 1
        } else {
            updated.lifetimeLongestPerfectGamesStreak = 0
        }
        
        // Win streaks
        if didWin {
            updated.lifetimeWinnings      += 1
            updated.currentWinningStreak += 1
        } else {
            updated.currentWinningStreak = 0
        }
        if updated.currentWinningStreak > self.analytics.lifetimeLongestWinningStreak {
            updated.lifetimeLongestWinningStreak = self.analytics.currentWinningStreak
        }
        
        // Achievements
        let achievements = self.getAchievements(updated)
        updated.achievementEarnedIDs   = achievements.ids
        updated.achievementEarnedDates = achievements.dates
        
        // Persist local + remote
        
        Self.saveToUserDefaults(self.analytics, forKey: self.defaultsKey)
        self.analytics = updated
        self.saveAnalytics { result in
            switch result {
            case .success():
                print("Analytics successfully saved to CloudKit.")
            case .failure(let error):
                print("Error saving analytics: \(error.localizedDescription)")
            }
        }
    }
    
    /// Asynchronously save analytics to CloudKit; call completion on main.
    func saveAnalytics(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let copy = analytics
        database.fetch(withRecordID: recordID) { [weak self] fetchedRecord, error in
            guard let self = self else { return }
            
            let record: CKRecord
            if let fetched = fetchedRecord {
                record = fetched
            } else {
                record = CKRecord(recordType: self.recordType, recordID: self.recordID)
            }
            
            // Snapshot on background is okay since analytics is immutable here
            record["lifetimeTotalScore"]                  = copy.lifetimeTotalScore        as CKRecordValue
            record["lifetimeTotalTimePlayed"]             = copy.lifetimeTotalTimePlayed    as CKRecordValue
            record["lifetimeCorrectShots"]                = copy.lifetimeCorrectShots       as CKRecordValue
            record["lifetimeMissedShots"]                 = copy.lifetimeMissedShots        as CKRecordValue
            record["lifetimeWinnings"]                    = copy.lifetimeWinnings           as CKRecordValue
            record["lifetimeGamesPlayed"]                 = copy.lifetimeGamesPlayed        as CKRecordValue
            record["lifetimeLongestWinningStreak"]        = copy.lifetimeLongestWinningStreak as CKRecordValue
            record["currentWinningStreak"]                = copy.currentWinningStreak        as CKRecordValue
            record["lastGameCorrectShots"]                = copy.lastGameCorrectShots        as CKRecordValue
            record["lastGameMissedShots"]                 = copy.lastGameMissedShots         as CKRecordValue
            record["lifetimePerfectGamesCount"]           = copy.lifetimePerfectGamesCount   as CKRecordValue
            record["lifetimeLongestPerfectGamesStreak"]   = copy.lifetimeLongestPerfectGamesStreak as CKRecordValue
            record["achievementEarnedIDs"]                = copy.achievementEarnedIDs        as CKRecordValue
            record["achievementEarnedDates"]              = copy.achievementEarnedDates      as CKRecordValue
            
            self.database.save(record) { _, saveError in
                DispatchQueue.main.async {
                    if let err = saveError {
                        completion(.failure(err))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
}
