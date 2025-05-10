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

enum AnalyticsError: Error, LocalizedError, CustomStringConvertible {
    case recordFound
    case iCloudNotAuthorized
    
    var description: String {
        switch self {
        case .recordFound:
            return "No records found"
        case .iCloudNotAuthorized:
            return "iCloud not authorized"
        }
    }
}

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
                print("CloudKit load analytics success!\n\n\n\(loaded)\n\n\n")
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
        print(#function)
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
    
    private func getAchievements(_ analytics: GameAnalytics)-> (dates: [Date], ids: [String]) {
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
    
    private static func loadFromUserDefaults(forKey key: SimpleDefaults.Key) -> GameAnalytics? {
        print(#function)
        guard
            let data: Data = SimpleDefaults.getValue(forKey: key) else {
            return nil
        }
        do {
            let data = try JSONDecoder().decode(GameAnalytics.self, from: data)
            print(data)
            return data
        } catch {
            print("loadFromUserDefaults error! \(error)")
            return nil
        }
    }
    
    private static func saveToUserDefaults(_ analytics: GameAnalytics, forKey key: SimpleDefaults.Key) {
        print(#function)

        do {
            let data = try JSONEncoder().encode(analytics)
            SimpleDefaults.setValue(data, forKey: key)
            print("saveToUserDefaults success!")
        } catch {
            print("saveToUserDefaults failed! \(error)")
        }
    }
    
    private func withICloudAvailability(_ block: @escaping (Bool) -> Void) {
        container.accountStatus { status, _ in
            DispatchQueue.main.async {
                block(status == .available)
            }
        }
    }
}

// MARK: - AnalyticsServiceProtocol

extension AnalyticsService: AnalyticsServiceProtocol {
    /// Asynchronously load analytics from CloudKit.
    func loadAnalytics(completion: @escaping (Result<GameAnalytics, Error>) -> Void) {
        withICloudAvailability { available in
            guard available else {
                // iCloud OFF → fall back to local + return
                completion(.failure(AnalyticsError.iCloudNotAuthorized))
                return
            }
            self.database.fetch(withRecordID: self.recordID) { record, error in
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
                    result = .failure(AnalyticsError.recordFound)
                }
                DispatchQueue.main.async {
                    print("DB load: \(result)")
                    completion(result)
                }
            }
        }
    }
    
    /// Update analytics on the main queue, then persist.
    func updateAnalytics(correctShots: Int,
                         missedShots: Int,
                         didWin: Bool,
                         finalScore: Int,
                         gameTimePlayed: Double) {
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
                
        // Perfect games
        if missedShots == 0 {
            updated.lifetimePerfectGamesCount += 1
            updated.lifetimeLongestPerfectGamesStreak += 1
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
        updated.lifetimeLongestWinningStreak = max(updated.lifetimeLongestWinningStreak, updated.currentWinningStreak)
        
        // Achievements
        let achievements = self.getAchievements(updated)
        updated.achievementEarnedIDs   = achievements.ids
        updated.achievementEarnedDates = achievements.dates
        print("updateAnalytics with the new values \(updated)")
        // Persist local + remote
        self.analytics = updated
        Self.saveToUserDefaults(updated, forKey: self.defaultsKey)
        self.saveAnalytics { result in
            switch result {
            case .success():
                print("=Analytics successfully saved to CloudKit.")
            case .failure(let error):
                print("=Error saving analytics: \(error.localizedDescription)")
            }
        }
    }
    
    /// Asynchronously save analytics to CloudKit; call completion on main.
    func saveAnalytics(completion: @escaping (Result<Void, Error>) -> Void) {
        print(#function)
        withICloudAvailability { available in
            guard available else {
                print("available: \(available)")
                completion(.failure(AnalyticsError.iCloudNotAuthorized))
                return
            }
            let copy = self.analytics
            self.database.fetch(withRecordID: self.recordID) { [weak self] fetchedRecord, error in
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
                            print("DB Saving error: \(err)")
                            completion(.failure(err))
                        } else {
                            print("DB Saving success")
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
}
