//
//  CloudSyncService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/10/25.
//

import Foundation
import CloudKit

protocol CloudSync {
    var userID: String { get }
    func fetchAnalyticsRecord(completion: @escaping (Result<GameAnalytics,Error>) -> Void)
    func saveAnalyticsRecord(_ analytics: GameAnalytics, completion: @escaping (Result<Void,Error>) -> Void)
}

enum CloudSyncError: Error, LocalizedError, CustomStringConvertible {
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

class CloudSyncService: CloudSync {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordID: CKRecord.ID
    private let recordType: String
    let userID: String
    
    init(container: CKContainer = .default(),
         recordName: String,
         recordType: String = "GameAnalytics") {
        self.container = container
        self.database        = container.privateCloudDatabase
        self.recordID  = CKRecord.ID(recordName: recordName)
        self.userID = recordName
        print(recordID)
        self.recordType = recordType
    }
    
    func fetchAnalyticsRecord(completion: @escaping (Result<GameAnalytics,Error>) -> Void) {
        database.fetch(withRecordID: recordID) { record, error in
            let result: Result<GameAnalytics, Error>
            if let error = error {
                result = .failure(error)
            } else if let record = record {
                let loaded = GameAnalytics(
                    lifetimeTotalScore:                   record["lifetimeTotalScore"]               as? Int    ?? 0,
                    lifetimeTotalTimePlayed:              record["lifetimeTotalTimePlayed"]          as? Double ?? 0,
                    lifetimeCorrectShots:                 record["lifetimeCorrectShots"]             as? Int    ?? 0,
                    lifetimeMissedShots:                  record["lifetimeMissedShots"]              as? Int    ?? 0,
                    lifetimeWinnings:                     record["lifetimeWinnings"]                 as? Int    ?? 0,
                    lifetimeGamesPlayed:                  record["lifetimeGamesPlayed"]              as? Int    ?? 0,
                    lifetimeLongestWinningStreak:         record["lifetimeLongestWinningStreak"]     as? Int    ?? 0,
                    currentWinningStreak:                 record["currentWinningStreak"]             as? Int    ?? 0,
                    currentPrefectWinningStreak:          record["currentPrefectWinningStreak"]      as? Int    ?? 0,
                    lastGameCorrectShots:                 record["lastGameCorrectShots"]             as? Int    ?? 0,
                    lastGameMissedShots:                  record["lastGameMissedShots"]              as? Int    ?? 0,
                    lifetimePerfectGamesCount:            record["lifetimePerfectGamesCount"]        as? Int    ?? 0,
                    lifetimeLongestPerfectGamesStreak:    record["lifetimeLongestPerfectGamesStreak"] as? Int    ?? 0,
                    achievementEarnedIDs:                 record["achievementEarnedIDs"]             as? [String] ?? [],
                    achievementEarnedDates:               record["achievementEarnedDates"]           as? [Date]  ?? []
                )
                result = .success(loaded)
            } else {
                result = .failure(CloudSyncError.recordFound)
            }
            DispatchQueue.main.async {
                print("DB load: \(result)")
                completion(result)
            }
        }
    }
    
    func saveAnalyticsRecord(_ analytics: GameAnalytics, completion: @escaping (Result<Void,Error>) -> Void) {
        database.fetch(withRecordID: self.recordID) { [weak self] fetchedRecord, error in
            guard let self else { return }
            let record: CKRecord
            if let fetched = fetchedRecord {
                record = fetched
            } else {
                record = CKRecord(recordType: self.recordType, recordID: self.recordID)
            }
            
            // Snapshot on background is okay since analytics is immutable here
            record["lifetimeTotalScore"]                  = analytics.lifetimeTotalScore        as CKRecordValue
            record["lifetimeTotalTimePlayed"]             = analytics.lifetimeTotalTimePlayed    as CKRecordValue
            record["lifetimeCorrectShots"]                = analytics.lifetimeCorrectShots       as CKRecordValue
            record["lifetimeMissedShots"]                 = analytics.lifetimeMissedShots        as CKRecordValue
            record["lifetimeWinnings"]                    = analytics.lifetimeWinnings           as CKRecordValue
            record["lifetimeGamesPlayed"]                 = analytics.lifetimeGamesPlayed        as CKRecordValue
            record["lifetimeLongestWinningStreak"]        = analytics.lifetimeLongestWinningStreak as CKRecordValue
            record["currentWinningStreak"]                = analytics.currentWinningStreak        as CKRecordValue
            record["lastGameCorrectShots"]                = analytics.lastGameCorrectShots        as CKRecordValue
            record["lastGameMissedShots"]                 = analytics.lastGameMissedShots         as CKRecordValue
            record["lifetimePerfectGamesCount"]           = analytics.lifetimePerfectGamesCount   as CKRecordValue
            record["lifetimeLongestPerfectGamesStreak"]   = analytics.lifetimeLongestPerfectGamesStreak as CKRecordValue
            record["currentPrefectWinningStreak"]         = analytics.currentPrefectWinningStreak as CKRecordValue
            record["achievementEarnedIDs"]                = analytics.achievementEarnedIDs        as CKRecordValue
            record["achievementEarnedDates"]              = analytics.achievementEarnedDates      as CKRecordValue
            
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

