//
//  AnalyticsService.swift
//  Roll Strike
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

// MARK: - Analytics Service Implementation

final class AnalyticsService: AnalyticsServiceProtocol, ObservableObject {
    
    // Use dependency injection by providing a recordName (unique per player).
    // For example: "GameAnalyticsRecord_<playerID>"
    init(recordName: String) {
        self.recordID = CKRecord.ID(recordName: recordName)
        self.defaultsKey = .gameAnalyticsData(recordName)
        container = CKContainer.default()
        database = container.privateCloudDatabase
        
        // Load locally first (UserDefaults fallback)
        if let local = Self.loadFromUserDefaults(forKey: defaultsKey) {
            analytics = local
        } else {
            analytics = GameAnalytics()
        }
        
        // Load from CloudKit asynchronously and update if available.
        loadAnalytics { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let loaded):
                    self.analytics = loaded
                    print("CloudKit load success: \(loaded)")
                    Self.saveToUserDefaults(loaded, forKey: self.defaultsKey)
                case .failure(let error):
                    print("CloudKit load error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Properties
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordID: CKRecord.ID
    private let defaultsKey: SimpleDefaults.Key
    
    @Published var analytics: GameAnalytics
    var analyticsPublisher: CurrentValueSubject<GameAnalytics, Never> {
        // Wrap our current value in a CurrentValueSubject
        CurrentValueSubject<GameAnalytics, Never>(analytics)
    }
    
    // MARK: - Public Methods
    
    /// Update analytics based on the game’s results.
    func updateAnalytics(correctShots: Int,
                         missedShots: Int,
                         didWin: Bool,
                         finalScore: Int,
                         gameTimePlayed: Double) {
        analytics.lifetimeTotalScore += finalScore
        analytics.lifetimeGamesPlayed += 1
        analytics.lastGameCorrectShots = correctShots
        analytics.lastGameMissedShots = missedShots
        analytics.lifetimeCorrectShots += correctShots
        analytics.lifetimeMissedShots += missedShots
        analytics.lifetimeTotalTimePlayed += gameTimePlayed
        
        if didWin {
            analytics.lifetimeWinnings += 1
            analytics.currentWinningStreak += 1
        } else {
            analytics.currentWinningStreak = 0
        }
        
        if analytics.currentWinningStreak > analytics.lifetimeLongestWinningStreak {
            analytics.lifetimeLongestWinningStreak = analytics.currentWinningStreak
        }
        
        // Save the updated analytics locally and to CloudKit.
        Self.saveToUserDefaults(analytics, forKey: defaultsKey)
        saveAnalytics { result in
            switch result {
            case .success():
                print("Analytics successfully saved to CloudKit.")
            case .failure(let error):
                print("Error saving analytics: \(error.localizedDescription)")
            }
        }
    }
    
    /// Asynchronously load analytics from CloudKit.
    func loadAnalytics(completion: @escaping (Result<GameAnalytics, Error>) -> Void) {
        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
            } else if let record = record {
                let loadedAnalytics = GameAnalytics(
                    lifetimeTotalScore: record["lifetimeTotalScore"] as? Int ?? 0,
                    lifetimeTotalTimePlayed: record["lifetimeTotalTimePlayed"] as? Double ?? 0,
                    lifetimeCorrectShots: record["lifetimeCorrectShots"] as? Int ?? 0,
                    lifetimeMissedShots: record["lifetimeMissedShots"] as? Int ?? 0,
                    lifetimeWinnings: record["lifetimeWinnings"] as? Int ?? 0,
                    lifetimeGamesPlayed: record["lifetimeGamesPlayed"] as? Int ?? 0,
                    lifetimeLongestWinningStreak: record["lifetimeLongestWinningStreak"] as? Int ?? 0,
                    currentWinningStreak: record["currentWinningStreak"] as? Int ?? 0,
                    lastGameCorrectShots: record["lastGameCorrectShots"] as? Int ?? 0,
                    lastGameMissedShots: record["lastGameMissedShots"] as? Int ?? 0
                )
                completion(.success(loadedAnalytics))
            } else {
                completion(.success(GameAnalytics()))
            }
        }
    }
    
    /// Asynchronously save analytics to CloudKit.
    func saveAnalytics(completion: @escaping (Result<Void, Error>) -> Void) {
        database.fetch(withRecordID: recordID) { [weak self] fetchedRecord, error in
            guard let self = self else { return }
            var record: CKRecord
            if let fetchedRecord = fetchedRecord {
                record = fetchedRecord
            } else {
                record = CKRecord(recordType: "GameAnalytics", recordID: self.recordID)
            }
            record["lifetimeTotalScore"] = self.analytics.lifetimeTotalScore as CKRecordValue
            record["lifetimeTotalTimePlayed"] = self.analytics.lifetimeTotalTimePlayed as CKRecordValue
            record["lifetimeCorrectShots"] = self.analytics.lifetimeCorrectShots as CKRecordValue
            record["lifetimeMissedShots"] = self.analytics.lifetimeMissedShots as CKRecordValue
            record["lifetimeWinnings"] = self.analytics.lifetimeWinnings as CKRecordValue
            record["lifetimeGamesPlayed"] = self.analytics.lifetimeGamesPlayed as CKRecordValue
            record["lifetimeLongestWinningStreak"] = self.analytics.lifetimeLongestWinningStreak as CKRecordValue
            record["currentWinningStreak"] = self.analytics.currentWinningStreak as CKRecordValue
            record["lastGameCorrectShots"] = self.analytics.lastGameCorrectShots as CKRecordValue
            record["lastGameMissedShots"] = self.analytics.lastGameMissedShots as CKRecordValue
            
            self.database.save(record) { savedRecord, saveError in
                DispatchQueue.main.async {
                    if let saveError = saveError {
                        completion(.failure(saveError))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // MARK: - Offline Persistence Helpers
    
    private static func loadFromUserDefaults(forKey key: SimpleDefaults.Key) -> GameAnalytics? {
        if let data: Data = SimpleDefaults.getValue(forKey: key),
           let decoded = try? JSONDecoder().decode(GameAnalytics.self, from: data) {
            return decoded
        }
        return nil
    }
    
    private static func saveToUserDefaults(_ analytics: GameAnalytics, forKey key: SimpleDefaults.Key) {
        if let data = try? JSONEncoder().encode(analytics) {
            SimpleDefaults.setValue(data, forKey: key)
        }
    }
}
