//
//  GameCenterAchievment.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/7/25.
//

import Foundation

enum GameCenterAchievment: String, CaseIterable {
    case firstWin = "rollstrike.firstwin"
    case fiveWins = "rollstrike.fiveWins"
    case twentyFiveWins = "rollstrike.twintyFiveWins"
    case fiveWinsStreak = "rollstrike.fiveWinStreak"
    case tenWinsStreak = "rollstrike.tenWinStreak"
    
    case firstGame = "rollstrike.firstGame"
    case tenGamesPlayed = "rollstrike.tenGames"
    case fiftyGamesPlayed = "rollstrike.fiftyGames"
    case oneHundredGamesPlayed = "rollstrike.oneHunderedGames"
    
    case firstPerfectGame = "rollstrike.firstPerfectGame"
    case fivePerfectGames = "rollstrike.fivePerfectGames"
    case tenPerfectGamesStreak = "rollstrike.tenPerfectGamesStreak"
    
    case score100 = "rollstrike.score100"
    case score200 = "rollstrike.score200"
    case score300 = "rollstrike.score300"
    case score400 = "rollstrike.score400"
    case score500 = "rollstrike.score500"
    
    case accuracy80 = "rollstrike.accuracy80"
    case accuracy90 = "rollstrike.accuracy90"
    case accuracy100 = "rollstrike.accuracy100"
    
    case playTime1Hour = "rollstrike.playTime1Hour"
    case playTime5Hours = "rollstrike.playTime5Hours"
    case playTime10Hours = "rollstrike.playTime10Hours"
    
    var imageName: String {
        var name: String
        switch self {
        case .firstWin:
            name = "First Win"
        case .fiveWins:
            name = "5 Wins"
        case .twentyFiveWins:
            name = "25 Wins"
        case .fiveWinsStreak:
            name = "5-Win Streak"
        case .tenWinsStreak:
            name = "10-Win Streak"
        case .firstGame:
            name = "First Game"
        case .tenGamesPlayed:
            name = "10 Games Played"
        case .fiftyGamesPlayed:
            name = "50 Games Played"
        case .oneHundredGamesPlayed:
            name = "100 Games Played"
        case .firstPerfectGame:
            name = "First Perfect Game"
        case .fivePerfectGames:
            name = "5 Perfect Games"
        case .tenPerfectGamesStreak:
            name = "10 Perfect-Game Streak"
        case .score100:
            name = "Score ≥ 100"
        case .score200:
            name = "Score ≥ 200"
        case .score300:
            name = "Score ≥ 300"
        case .score400:
            name = "Score ≥ 400"
        case .score500:
            name = "Score ≥ 500"
        case .accuracy80:
            name = "Accuracy ≥ 80%"
        case .accuracy90:
            name = "Accuracy ≥ 90%"
        case .accuracy100:
            name = "Accuracy = 100%"
        case .playTime1Hour:
            name = "Play Time ≥ 1 hr"
        case .playTime5Hours:
            name = "Play Time ≥ 5 hrs"
        case .playTime10Hours:
            name = "Play Time ≥ 10 hrs"
        }
        return name
    }
}

extension GameCenterAchievment {
    static func getAchievementsObtained(for score: Int, analytics: GameAnalytics) -> [GameCenterAchievment] {
        let totalGames = analytics.lifetimeGamesPlayed
        let totalWins = analytics.lifetimeWinnings
        let winningStreak = analytics.currentWinningStreak
        let playTotalTime   = analytics.lifetimeTotalTimePlayed
        let perfectGames = analytics.lifetimePerfectGamesCount
        let perfectStreak = analytics.lifetimeLongestPerfectGamesStreak
        let accuracy = analytics.accuracy
        
        return achievementsToReport(
            totalWins: totalWins,
            currentStreak: winningStreak,
            finalScore: score,
            totalGames: totalGames,
            totalTime: playTotalTime,
            perfectGames: perfectGames,
            perfectStreak: perfectStreak,
            accuracy: accuracy
        )
    }
    
    private static func achievementsToReport(totalWins: Int,
                                     currentStreak: Int,
                                     finalScore: Int,
                                     totalGames: Int,
                                     totalTime: Double,
                                     perfectGames: Int,
                                     perfectStreak: Int,
                                     accuracy: Double) -> [GameCenterAchievment] {
        return winsAchievements(for: totalWins)
        + streakAchievements(for: currentStreak)
        + gamesPlayedAchievements(for: totalGames)
        + perfectGamesAchievements(for: perfectGames)
        + perfectStreakAchievements(for: perfectStreak)
        + highScoreAchievements(for: finalScore)
        + accuracyAchievements(for: accuracy)
        + playTimeAchievements(for: totalTime)
    }
    
    private static func winsAchievements(for totalWins: Int) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if totalWins >= 1  { list.append(.firstWin) }
        if totalWins >= 5  { list.append(.fiveWins) }
        if totalWins >= 25 { list.append(.twentyFiveWins) }
        return list
    }
    
    private static func streakAchievements(for currentStreak: Int) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if currentStreak >= 5  { list.append(.fiveWinsStreak) }
        if currentStreak >= 10 { list.append(.tenWinsStreak) }
        return list
    }
    
    private static func gamesPlayedAchievements(for totalGames: Int) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if totalGames >= 1   { list.append(.firstGame) }
        if totalGames >= 10  { list.append(.tenGamesPlayed) }
        if totalGames >= 50  { list.append(.fiftyGamesPlayed) }
        if totalGames >= 100 { list.append(.oneHundredGamesPlayed) }
        return list
    }
    
    private static func perfectGamesAchievements(for perfectGames: Int) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if perfectGames >= 1 { list.append(.firstPerfectGame) }
        if perfectGames >= 5 { list.append(.fivePerfectGames) }
        return list
    }
    
    private static func perfectStreakAchievements(for perfectStreak: Int) -> [GameCenterAchievment] {
        return perfectStreak >= 10
        ? [.tenPerfectGamesStreak]
        : []
    }
    
    private static func highScoreAchievements(for finalScore: Int) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if finalScore >= 100 { list.append(.score100) }
        if finalScore >= 200 { list.append(.score200) }
        if finalScore >= 300 { list.append(.score300) }
        if finalScore >= 400 { list.append(.score400) }
        if finalScore >= 500 { list.append(.score500) }
        return list
    }
    
    private static func accuracyAchievements(for accuracy: Double) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if accuracy >= 0.8 { list.append(.accuracy80) }
        if accuracy >= 0.9 { list.append(.accuracy90) }
        if accuracy == 1.0 { list.append(.accuracy100) }
        return list
    }
    
    private static func playTimeAchievements(for totalTime: Double) -> [GameCenterAchievment] {
        var list = [GameCenterAchievment]()
        if totalTime >=  3600       { list.append(.playTime1Hour) }
        if totalTime >=  5 * 3600   { list.append(.playTime5Hours) }
        if totalTime >= 10 * 3600   { list.append(.playTime10Hours) }
        return list
    }
}

extension GameCenterAchievment {
    /// Returns an array of all `Achievement` models, one per enum case.
    static func allAchievements() -> [Achievement] {
        return Self.allCases.map { ach in
            switch ach {
            case .firstWin:
                return Achievement(
                    id: ach.rawValue,
                    title: "First Win",
                    preEarnedDesc: "Win your first game to unlock a trophy!",
                    earnedDesc: "Congratulations! You’ve claimed your First Win trophy!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .fiveWins:
                return Achievement(
                    id: ach.rawValue,
                    title: "5 Wins",
                    preEarnedDesc: "Rack up 5 victories to prove your skill.",
                    earnedDesc: "Well done! You’ve won 5 games—keep it going!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .twentyFiveWins:
                return Achievement(
                    id: ach.rawValue,
                    title: "25 Wins",
                    preEarnedDesc: "Push through 25 wins to earn your champion badge.",
                    earnedDesc: "Amazing! You’re now a 25-time champion!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .fiveWinsStreak:
                return Achievement(
                    id: ach.rawValue,
                    title: "5-Win Streak",
                    preEarnedDesc: "Score five wins in a row to join the elite.",
                    earnedDesc: "Unstoppable! 5 consecutive victories earned!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .tenWinsStreak:
                return Achievement(
                    id: ach.rawValue,
                    title: "10-Win Streak",
                    preEarnedDesc: "Ten straight wins—can you handle the heat?",
                    earnedDesc: "Legendary! 10-game winning streak!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .firstGame:
                return Achievement(
                    id: ach.rawValue,
                    title: "First Game",
                    preEarnedDesc: "Play your very first game to get started.",
                    earnedDesc: "Great start! You’ve completed your first game!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .tenGamesPlayed:
                return Achievement(
                    id: ach.rawValue,
                    title: "10 Games Played",
                    preEarnedDesc: "Play 10 games to become a seasoned player.",
                    earnedDesc: "Nicely done! You’ve played 10 games.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .fiftyGamesPlayed:
                return Achievement(
                    id: ach.rawValue,
                    title: "50 Games Played",
                    preEarnedDesc: "Tackle 50 games to unlock this badge.",
                    earnedDesc: "Milestone reached: 50 games played!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .oneHundredGamesPlayed:
                return Achievement(
                    id: ach.rawValue,
                    title: "100 Games Played",
                    preEarnedDesc: "Hit 100 games for the century club.",
                    earnedDesc: "Centurion! You’ve hit 100 games.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .firstPerfectGame:
                return Achievement(
                    id: ach.rawValue,
                    title: "First Perfect Game",
                    preEarnedDesc: "Score a perfect game (no misses) to shine.",
                    earnedDesc: "Flawless! Your first perfect game!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .fivePerfectGames:
                return Achievement(
                    id: ach.rawValue,
                    title: "5 Perfect Games",
                    preEarnedDesc: "Achieve 5 flawless games for perfection.",
                    earnedDesc: "Impeccable! 5 perfect games under your belt.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .tenPerfectGamesStreak:
                return Achievement(
                    id: ach.rawValue,
                    title: "10 Perfect-Game Streak",
                    preEarnedDesc: "10 perfect games in a row? Only the best can do it.",
                    earnedDesc: "Perfectionist! 10 flawless games in a row!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .score100:
                return Achievement(
                    id: ach.rawValue,
                    title: "Score ≥ 100",
                    preEarnedDesc: "Reach 100 points to earn the Bronze score badge.",
                    earnedDesc: "Bravo! You’ve reached 100 points.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .score200:
                return Achievement(
                    id: ach.rawValue,
                    title: "Score ≥ 200",
                    preEarnedDesc: "200 points unlocks the Silver score badge.",
                    earnedDesc: "Impressive! You’ve reached 200 points.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .score300:
                return Achievement(
                    id: ach.rawValue,
                    title: "Score ≥ 300",
                    preEarnedDesc: "300 points — the Gold score badge awaits!",
                    earnedDesc: "Exceptional! 300 points is gold-standard.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .score400:
                return Achievement(
                    id: ach.rawValue,
                    title: "Score ≥ 400",
                    preEarnedDesc: "400 points gets the Platinum score badge.",
                    earnedDesc: "Outstanding! You’ve hit 400 points.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .score500:
                return Achievement(
                    id: ach.rawValue,
                    title: "Score ≥ 500",
                    preEarnedDesc: "Half-thousand points unlocks the Diamond badge.",
                    earnedDesc: "Incredible! 500-point Diamond achieved!",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .accuracy80:
                return Achievement(
                    id: ach.rawValue,
                    title: "Accuracy ≥ 80%",
                    preEarnedDesc: "Keep your accuracy above 80% to earn the Sharpshooter.",
                    earnedDesc: "Good aim! 80% accuracy badge unlocked.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .accuracy90:
                return Achievement(
                    id: ach.rawValue,
                    title: "Accuracy ≥ 90%",
                    preEarnedDesc: "90% accuracy separates the pros.",
                    earnedDesc: "Excellent shot-calling! 90% accuracy badge earned.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .accuracy100:
                return Achievement(
                    id: ach.rawValue,
                    title: "Accuracy = 100%",
                    preEarnedDesc: "Perfection means 100% accuracy—claim your crown.",
                    earnedDesc: "Spot-on! 100% accuracy achieved.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .playTime1Hour:
                return Achievement(
                    id: ach.rawValue,
                    title: "Play Time ≥ 1 hr",
                    preEarnedDesc: "Play for 1 hour total to unlock the Timekeeper badge.",
                    earnedDesc: "Était long journey! 1 hour of playtime logged.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .playTime5Hours:
                return Achievement(
                    id: ach.rawValue,
                    title: "Play Time ≥ 5 hrs",
                    preEarnedDesc: "5 hours of play unlocks the Marathon badge.",
                    earnedDesc: "Endurance proven! 5 hours played.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            case .playTime10Hours:
                return Achievement(
                    id: ach.rawValue,
                    title: "Play Time ≥ 10 hrs",
                    preEarnedDesc: "10 hours of playtime earns the Legend badge.",
                    earnedDesc: "Legendary! 10 hours of playtime.",
                    badgeImageName: ach.imageName,
                    isEarned: false,
                    dateEarned: nil
                )
            }
        }
    }
}
