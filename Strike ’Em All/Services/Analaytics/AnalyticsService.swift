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
}

final class AnalyticsService: ObservableObject {
    /// The single, authoritative subject for analytics updates
    let analyticsPublisher: CurrentValueSubject<GameAnalytics, Never>
    @Published private(set) var analytics: GameAnalytics {
        didSet {
            analyticsPublisher.send(analytics)
        }
    }
    
    private let player: Player
    private let filename: String
    private let disk: Persistence
    private let cloud: CloudSyncServiceProtocol
    private let availability: CloudAvailabilityChecking
    
    private var cancellables = Set<AnyCancellable>()
    
    private var recordID: CKRecord.ID {
        CKRecord.ID(recordName: recordName)
    }
    
    private var recordName: String {
        "\(player.id)_analytics"
    }
    
    init(disk: Persistence,
         player: Player,
         cloud: CloudSyncServiceProtocol,
         availability: CloudAvailabilityChecking = CloudAvailabilityService()) {
        self.player = player
        self.disk = disk
        self.cloud = cloud
        self.availability = availability
        self.filename = "\(player.id)_analytics.json"
       
        var initail = GameAnalytics()
        print("Initial analytics \(initail)")
        if let stored = try? disk.load(GameAnalytics.self, from: filename) {
            initail = stored
            print("From file analytics \(initail)")
        }
        
        analytics = initail
        analyticsPublisher = CurrentValueSubject(initail)
        
        availability
            .iCloudAvailability()
            .sink { [weak self] available in
                guard let self = self else { return }
                if available {
                    self.loadFromCloudKit()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadFromCloudKit() {
        cloud.fetchRecord(recordID: recordID) { [weak self] (result: Result<GameAnalytics, Error>) in
            guard let self = self else { return }
            switch result {
            case let .success(cloudAnalytics):
                print("Load analytics success")
                FileLogger.shared.log("Load analytics success", level: .debug)
                self.mergeAnalytics(cloudAnalytics, self.analytics)
                try? self.disk.save(self.analytics, to: filename)
                self.saveAnalyticsToCloud()
            case .failure(let error as CKError) where error.code == .unknownItem:
                // no record exists yet—upload our initial analytics
                FileLogger.shared.log("No cloud record yet; uploading initial analytics…", level: .error)
                self.saveAnalyticsToCloud()
                
            case .failure(let error):
                FileLogger.shared.log("Load analytics error \(recordName): \(error)", level: .error)
            }
        }
    }
    
    private func mergeAnalytics(_ a1: GameAnalytics, _ a2: GameAnalytics) {
        var merged = GameAnalytics()
        
        // 1) For every numeric property, pick the larger value
        merged.lifetimeTotalScore = max(a1.lifetimeTotalScore, a2.lifetimeTotalScore)
        merged.lifetimeTotalTimePlayed = max(a1.lifetimeTotalTimePlayed, a2.lifetimeTotalTimePlayed)
        merged.lifetimeCorrectShots = max(a1.lifetimeCorrectShots, a2.lifetimeCorrectShots)
        merged.lifetimeMissedShots = max(a1.lifetimeMissedShots, a2.lifetimeMissedShots)
        merged.lifetimeWinnings = max(a1.lifetimeWinnings, a2.lifetimeWinnings)
        merged.lifetimeGamesPlayed = max(a1.lifetimeGamesPlayed, a2.lifetimeGamesPlayed)
        merged.lifetimePerfectGamesCount = max(a1.lifetimePerfectGamesCount, a2.lifetimePerfectGamesCount)
        
        merged.lifetimeLongestWinningStreak = max(a1.lifetimeLongestWinningStreak, a2.lifetimeLongestWinningStreak)
        
        merged.currentWinningStreak = max(a1.currentWinningStreak, a2.currentWinningStreak)
        
        merged.lifetimeLongestPerfectGamesStreak = max(a1.lifetimeLongestPerfectGamesStreak, a2.lifetimeLongestPerfectGamesStreak)
        
        merged.lifetimeLongestPerfectGamesStreak = max(merged.currentWinningStreak, merged.lifetimeLongestPerfectGamesStreak)
        
        merged.currentPrefectWinningStreak = max(a1.currentPrefectWinningStreak, a2.currentPrefectWinningStreak)
        
        // If there is a perfect game then longest would be at least one
        if merged.lifetimeLongestPerfectGamesStreak == 0,
            merged.lifetimePerfectGamesCount > 0 {
            merged.lifetimeLongestPerfectGamesStreak = 1
        }
        
        merged.lastGameCorrectShots = max(a1.lastGameCorrectShots, a2.lastGameCorrectShots)
        merged.lastGameMissedShots  = max(a1.lastGameMissedShots, a2.lastGameMissedShots)
        
        var dateByID: [String: Date] = [:]
        func collect(_ analytics: GameAnalytics) {
            for (id, date) in zip(analytics.achievementEarnedIDs, analytics.achievementEarnedDates) {
                if let existingDate = dateByID[id] {
                    dateByID[id] = min(existingDate, date)
                } else {
                    dateByID[id] = date
                }
            }
        }
        collect(a1)
        collect(a2)
        let sortedIDs = dateByID.keys.sorted { dateByID[$0]! < dateByID[$1]! }
        merged.achievementEarnedIDs   = sortedIDs
        merged.achievementEarnedDates = sortedIDs.map { dateByID[$0]! }
        
        analytics = merged
        FileLogger.shared.log("Merged complete!", object: analytics, level: .debug)
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
    
    private func saveAnalyticsToCloud() {
        availability
            .iCloudAvailability()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available in
                guard let self else  { return }
                if available {
                    self.cloud.saveRecord(self.analytics, recordID: recordID) { _ in
                        // No info
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - AnalyticsServiceProtocol

extension AnalyticsService: AnalyticsServiceProtocol {
    /// Update analytics on the main queue, then persist.
    func updateAnalytics(correctShots: Int,
                         missedShots: Int,
                         didWin: Bool,
                         finalScore: Int,
                         gameTimePlayed: Double) {
        var updated = self.analytics
        // Update lifetime metrics
        updated.lifetimeTotalScore       += finalScore
        updated.lifetimeGamesPlayed      += 1
        updated.lastGameCorrectShots      = correctShots
        updated.lastGameMissedShots       = missedShots
        updated.lifetimeCorrectShots     += correctShots
        updated.lifetimeMissedShots      += missedShots
        updated.lifetimeTotalTimePlayed  += gameTimePlayed
                
        // Win streaks
        if didWin {
            updated.lifetimeWinnings      += 1
            updated.currentWinningStreak += 1
        } else {
            updated.currentWinningStreak = 0
        }
        updated.lifetimeLongestWinningStreak = max(updated.lifetimeLongestWinningStreak, updated.currentWinningStreak)
        
        // Perfect games Streak
        if missedShots == 0 {
            updated.lifetimePerfectGamesCount += 1
            updated.currentPrefectWinningStreak += 1
        } else {
            updated.currentPrefectWinningStreak = 0
        }
        updated.lifetimeLongestPerfectGamesStreak = max(updated.lifetimeLongestPerfectGamesStreak, updated.currentPrefectWinningStreak)
        
        if updated.lifetimeLongestPerfectGamesStreak == 0,
           updated.lifetimePerfectGamesCount > 0 {
            updated.lifetimeLongestPerfectGamesStreak = 1
        }
        
        // Achievements
        let achievements = self.getAchievements(updated)
        updated.achievementEarnedIDs   = achievements.ids
        updated.achievementEarnedDates = achievements.dates
        
        self.analytics = updated
        FileLogger.shared.log("Update complete!", object: analytics, level: .debug)
        try? disk.save(updated, to: filename)
        saveAnalyticsToCloud()
    }
}
