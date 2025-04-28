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

final class PlayerService: ObservableObject, ClassNameRepresentable {
    static let shared = PlayerService()
    let playersSubject = CurrentValueSubject<[Player], Never>([])
    private let playersKey = "SavedPlayers"
    private let kvStore = NSUbiquitousKeyValueStore.default
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeysDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
        loadPlayers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func savePlayers(_ list: [Player]) {
        let snapshot = list
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                UserDefaults.standard.set(data, forKey: self.playersKey)
                self.kvStore.set(data, forKey: self.playersKey)
                self.kvStore.synchronize()
            } catch {
                print(error)
            }
        }
    }
    
    private func loadPlayers() {
        DispatchQueue.global(qos: .background).async {
            let data = self.kvStore.data(forKey: self.playersKey)
            ?? UserDefaults.standard.data(forKey: self.playersKey)
            
            let list: [Player]
            if let data {
                do {
                    let decoded = try JSONDecoder().decode([Player].self, from: data)
                    list = decoded.sorted { $0.lastUsed > $1.lastUsed }
                } catch {
                    print(error)
                    list = []
                }
            } else {
                list = []
            }
            DispatchQueue.main.async {
                self.playersSubject.send(list)
            }
        }
    }
    
    @objc private func ubiquitousKeysDidChange(_ note: Notification) {
        loadPlayers()
    }
}

// MARK: - PlayerRepositoryProtocol
extension PlayerService: PlayerRepositoryProtocol {
    func reload() { loadPlayers() }
    
    func getLastUsed() -> Player? { playersSubject.value.first }
    
    func save(_ player: Player) {
        var current = playersSubject.value
        if let idx = current.firstIndex(where: { $0.id == player.id }) {
            current[idx].name = player.name
            current[idx].lastUsed = Date()
        } else {
            current.append(player)
        }
        let updated = current.sorted { $0.lastUsed > $1.lastUsed }
        playersSubject.send(updated)
        savePlayers(updated)
    }
    
    func delete(_ player: Player) {
        let updated = playersSubject.value.filter { $0.id != player.id }
        playersSubject.send(updated)
        savePlayers(updated)
    }
}
