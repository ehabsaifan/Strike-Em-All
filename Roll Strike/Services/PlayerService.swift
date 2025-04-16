//
//  PlayerService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import Foundation
import Combine

final class PlayerService: ObservableObject, ClassNameRepresentable {
    static let shared = PlayerService()
    @Published var players: [Player] = []
    
    private let playersKey = "SavedPlayers"
    
    private init() {
        print("\(className): \(#function)")
        loadPlayers()
    }
    
    private func loadPlayers() {
        if let data: Data = UserDefaults.standard.data(forKey: playersKey),
           let savedPlayers = try? JSONDecoder().decode([Player].self, from: data) {
            // Sort by most recent usage.
            players = savedPlayers.sorted { $0.lastUsed > $1.lastUsed }
        } else {
            players = []
        }
        print("\(className): \(#function)")
    }
    
    private func savePlayers() {
        do {
            let data = try JSONEncoder().encode(players)
            UserDefaults.standard.set(data, forKey: playersKey)
        } catch {
            print(error)
        }
    }
    
    func reloadPlayers() {
        loadPlayers()
        print("\(className): \(#function)")
    }
    
    func addOrUpdatePlayer(_ player: Player) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            // Update lastUsed and name.
            players[index].lastUsed = Date()
            players[index].name = player.name
        } else {
            players.append(player)
        }
        players.sort { $0.lastUsed > $1.lastUsed }
        savePlayers()
        print("\(className): \(#function)")
    }
    
    func deletePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
        savePlayers()
        print("\(className): \(#function)")
    }
    
    func getLastUsedPlayer() -> Player? {
        print("\(className): \(#function)")
        return players.first
    }
}
