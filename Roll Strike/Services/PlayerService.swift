//
//  PlayerService.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/13/25.
//

import Foundation
import Combine

protocol PlayerRepositoryProtocol {
    var playersSubject: CurrentValueSubject<[Player], Never> { get }
    
    func reload()
    func getLastUsed() -> Player?
    func save(_ player: Player)
    func delete(_ player: Player)
}

final class PlayerService: ObservableObject, ClassNameRepresentable, PlayerRepositoryProtocol {    
    static let shared = PlayerService()
    let playersSubject = CurrentValueSubject<[Player], Never>([])
    
    private let playersKey = "SavedPlayers"
    
    
    private init() {
        loadPlayers()
    }

    
    private func loadPlayers() {
        if let data: Data = UserDefaults.standard.data(forKey: playersKey),
           let savedPlayers = try? JSONDecoder().decode([Player].self, from: data) {
            // Sort by most recent usage.
            let loaded = savedPlayers.sorted { $0.lastUsed > $1.lastUsed }
            playersSubject.send(loaded)
        } else {
            playersSubject.send([])
        }
    }
    
    private func savePlayers() {
        do {
            let current = playersSubject.value
            let data = try JSONEncoder().encode(current)
            UserDefaults.standard.set(data, forKey: playersKey)
        } catch {
            print(error)
        }
    }
    
    func reload() {
        loadPlayers()
    }
    
    func save(_ player: Player) {
        var current = playersSubject.value
        if let index = current.firstIndex(where: { $0.id == player.id }) {
            // Update lastUsed and name.
            current[index].lastUsed = Date()
            current[index].name = player.name
        } else {
            current.append(player)
        }
        current.sort { $0.lastUsed > $1.lastUsed }
        playersSubject.send(current)
        savePlayers()
    }
    
    func delete(_ player: Player) {
        var current = playersSubject.value
        current.removeAll { $0.id == player.id }
        playersSubject.send(current)
        savePlayers()
    }
    
    func getLastUsed() -> Player? {
        return playersSubject.value.first
    }
}
