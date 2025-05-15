//
//  CloudSyncService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/10/25.
//

import Foundation
import CloudKit

protocol CKRecordConvertible {
    static var recordType: CKRecord.RecordType { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    init?(record: CKRecord)
    func toRecord(recordID: CKRecord.ID) -> CKRecord
}

protocol CloudSyncServiceProtocol {
    func fetchRecord<T: CKRecordConvertible>(recordID: CKRecord.ID,
                                             completion: @escaping (Result<T,Error>) -> Void)
    
    func fetchAll<T: CKRecordConvertible>(ofType type: T.Type,
                                          completion: @escaping (Result<[T], Error>) -> Void)
    
    func saveRecord<T: CKRecordConvertible>(_ object: T,
                                            recordID: CKRecord.ID,
                                            completion: @escaping (Result<Void,Error>) -> Void)
    
    func saveRecords<T: CKRecordConvertible>(
        _ objects: [(obj: T, recordID: CKRecord.ID)],
        completion: @escaping (Result<Void, Error>) -> Void)
    
    func deleteRecord(recordID: CKRecord.ID, completion: @escaping (Result<Void,Error>) -> Void)
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

class CloudSyncService: CloudSyncServiceProtocol {
    private let container: CKContainer
    private let database: CKDatabase
    
    init(container: CKContainer = .default()) {
        self.container = container
        self.database = container.privateCloudDatabase
    }
    
    func fetchRecord<T: CKRecordConvertible>(recordID: CKRecord.ID, completion: @escaping (Result<T,Error>) -> Void) {
        database.fetch(withRecordID: recordID) { record, error in
            let result: Result<T, Error>
            if let error = error {
                print("DB load error. \(error)")
                result = .failure(error)
            } else if let record = record,
                      let loaded = T(record: record) {
                print("DB load success: \(loaded)")
                result = .success(loaded)
            } else {
                print("DB load error. Record not found")
                result = .failure(CloudSyncError.recordFound)
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func fetchAll<T: CKRecordConvertible>(
        ofType type: T.Type,
        completion: @escaping (Result<[T],Error>) -> Void
    ) {
        var accumulator = [T]()
        
        let query = CKQuery(
            recordType: T.recordType,
            predicate: NSPredicate(value: true)
        )
        // this replaces the implicit recordName sort
       query.sortDescriptors = T.defaultSortDescriptors
        
        func page(cursor: CKQueryOperation.Cursor?) {
            let handler: (Result<
                          (matchResults: [(CKRecord.ID,Result<CKRecord,Error>)],
                           queryCursor: CKQueryOperation.Cursor?),
                          Error
                          >) -> Void = { pageResult in
                switch pageResult {
                case .failure(let err):
                    print("Fetch all record error. \(err)")
                    DispatchQueue.main.async { completion(.failure(err)) }
                case .success(let (matches, nextCursor)):
                    for (_, recordRes) in matches {
                        if case let .success(rec) = recordRes {
                            if let obj = T(record: rec) {
                                print("Fetch all record success \(obj)")
                                accumulator.append(obj)
                            } else {
                                print("Could not be converted")
                            }
                        } else {
                            print("Fetch all record failed \(recordRes)")
                        }
                    }
                    if let next = nextCursor {
                        page(cursor: next)
                    } else {
                        DispatchQueue.main.async { completion(.success(accumulator)) }
                    }
                }
            }
            
            if let cur = cursor {
                database.fetch(withCursor: cur, completionHandler: handler)
            } else {
                database.fetch(withQuery: query, completionHandler: handler)
            }
        }
        
        page(cursor: nil)
    }
    
    func saveRecord<T: CKRecordConvertible>(
        _ object: T,
        recordID: CKRecord.ID,
        completion: @escaping (Result<Void,Error>) -> Void
    ) {
        let record = object.toRecord(recordID: recordID)
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        op.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Saving record success \(object)")
                    completion(.success(()))
                case .failure(let error):
                    print("Saving record error \(object). \(error)")
                    completion(.failure(error))
                }
            }
        }
        database.add(op)
    }
    
    func saveRecords<T: CKRecordConvertible>(
        _ objects: [(obj: T, recordID: CKRecord.ID)],
        completion: @escaping (Result<Void, Error>) -> Void) {
            // build CKRecords for each object
            let records = objects.map { item in
                return item.obj.toRecord(recordID: item.recordID)
            }
            // batch modify
            let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            op.savePolicy = .changedKeys
            op.modifyRecordsResultBlock = { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("saveRecords success")
                        completion(.success(()))
                    case .failure(let err):
                        print("saveRecords faild", err)
                        completion(.failure(err))
                    }
                }
            }
            database.add(op)
        }
    
    func deleteRecord(recordID: CKRecord.ID,
                      completion: @escaping (Result<Void,Error>) -> Void) {
        let op = CKModifyRecordsOperation(recordsToSave: nil,
                                          recordIDsToDelete: [recordID])
        op.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Deleted record \(recordID)")
                    completion(.success(()))
                case .failure(let err):
                    print("Failed to delete \(recordID):", err)
                    completion(.failure(err))
                }
            }
        }
        database.add(op)
    }
}

extension GameAnalytics: CKRecordConvertible {
    static var recordType: CKRecord.RecordType { "GameAnalytics" }
    static var defaultSortDescriptors: [NSSortDescriptor] {
        // e.g. most-recent-updated‐first, or highest score
        [NSSortDescriptor(key: "lifetimeTotalScore", ascending: false)]
    }
    
    func toRecord(recordID: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["lifetimeTotalScore"]                  = lifetimeTotalScore as CKRecordValue
        record["lifetimeTotalTimePlayed"]             = lifetimeTotalTimePlayed as CKRecordValue
        record["lifetimeCorrectShots"]                = lifetimeCorrectShots as CKRecordValue
        record["lifetimeMissedShots"]                 = lifetimeMissedShots as CKRecordValue
        record["lifetimeWinnings"]                    = lifetimeWinnings as CKRecordValue
        record["lifetimeGamesPlayed"]                 = lifetimeGamesPlayed as CKRecordValue
        record["lifetimeLongestWinningStreak"]        = lifetimeLongestWinningStreak as CKRecordValue
        record["currentWinningStreak"]                = currentWinningStreak as CKRecordValue
        record["lastGameCorrectShots"]                = lastGameCorrectShots as CKRecordValue
        record["lastGameMissedShots"]                 = lastGameMissedShots as CKRecordValue
        record["lifetimePerfectGamesCount"]           = lifetimePerfectGamesCount as CKRecordValue
        record["lifetimeLongestPerfectGamesStreak"]   = lifetimeLongestPerfectGamesStreak as CKRecordValue
        record["currentPrefectWinningStreak"]         = currentPrefectWinningStreak as CKRecordValue
        record["achievementEarnedIDs"]                = achievementEarnedIDs as CKRecordValue
        record["achievementEarnedDates"]              = achievementEarnedDates as CKRecordValue
        return record
    }
    
    init?(record: CKRecord) {
        self.lifetimeTotalScore =                 record["lifetimeTotalScore"] as? Int ?? 0
        self.lifetimeTotalTimePlayed =            record["lifetimeTotalTimePlayed"] as? Double ?? 0
        self.lifetimeCorrectShots =               record["lifetimeCorrectShots"] as? Int ?? 0
        self.lifetimeMissedShots =                record["lifetimeMissedShots"] as? Int ?? 0
        self.lifetimeWinnings =                   record["lifetimeWinnings"] as? Int ?? 0
        self.lifetimeGamesPlayed =                record["lifetimeGamesPlayed"] as? Int ?? 0
        self.lifetimeLongestWinningStreak =       record["lifetimeLongestWinningStreak"] as? Int ?? 0
        self.currentWinningStreak =               record["currentWinningStreak"] as? Int ?? 0
        self.currentPrefectWinningStreak =        record["currentPrefectWinningStreak"] as? Int ?? 0
        self.lastGameCorrectShots =               record["lastGameCorrectShots"] as? Int ?? 0
        self.lastGameMissedShots =                record["lastGameMissedShots"] as? Int ?? 0
        self.lifetimePerfectGamesCount =          record["lifetimePerfectGamesCount"] as? Int ?? 0
        self.lifetimeLongestPerfectGamesStreak =  record["lifetimeLongestPerfectGamesStreak"] as? Int ?? 0
        self.achievementEarnedIDs =               record["achievementEarnedIDs"] as? [String] ?? []
        self.achievementEarnedDates =             record["achievementEarnedDates"] as? [Date] ?? []
    }
}

extension Player: CKRecordConvertible {
    static var recordType: CKRecord.RecordType { "Player" }
    static var defaultSortDescriptors: [NSSortDescriptor] {
        // sort by lastUsed descending
        [NSSortDescriptor(key: "lastUsed", ascending: false)]
    }
    
    /// Build a CKRecord from this Player
    func toRecord(recordID: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["gcPlayerID"] = gcPlayerID as CKRecordValue
        record["id"]       = id as CKRecordValue
        record["name"]     = name as CKRecordValue
        record["type"]     = type.rawValue as CKRecordValue
        record["lastUsed"] = lastUsed as CKRecordValue
        return record
    }
    
    /// Initialize a Player from a fetched CKRecord
    init?(record: CKRecord) {
        guard record.recordType == Self.recordType else {
            print("Wrong conversion")
            return nil
        }
        guard
            let gcPlayerID = record["gcPlayerID"] as? String,
            let name     = record["name"]     as? String,
            let typeRaw  = record["type"]     as? String,
            let type     = PlayerType(rawValue: typeRaw),
            let lastUsed = record["lastUsed"] as? Date
        else {
            return nil
        }
        self.gcPlayerID = gcPlayerID
        self.id       = record.recordID.recordName
        self.name     = name
        self.type     = type
        self.lastUsed = lastUsed
    }
}
