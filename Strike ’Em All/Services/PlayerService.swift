//
//  PlayerService.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 4/13/25.
//

import Foundation
import Combine
import CloudKit

protocol PlayerRepositoryProtocol {
    var playersSubject: CurrentValueSubject<[Player], Never> { get }
    
    func reload()
    func getLastUsed() -> Player?
    func save(_ player: Player)
    func delete(_ player: Player)
}

final class PlayerService: ObservableObject, ClassNameRepresentable {
    let playersSubject = CurrentValueSubject<[Player], Never>([])
    private let cloud: CloudSyncServiceProtocol
    private let filename: String
    private let disk: Persistence
    
    init(disk: Persistence,
         cloudSyncService: CloudSyncServiceProtocol) {
        self.disk = disk
        self.cloud = cloudSyncService
        self.filename = "players.json"
        
        loadLocalPlayers { [weak self] in
            guard let self = self else { return }
            self.cloud.fetchAll(ofType: Player.self) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let err):
                    print("⚠️ couldn’t fetch players from CloudKit: \(err)")
                case .success(let cloudPlayers):
                    self.merge(cloudPlayers: cloudPlayers)
                    try? self.disk.save(self.playersSubject.value, to: self.filename)
                    self.saveToCloud()
                }
            }
            
        }
    }
    
    private func loadLocalPlayers(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            var diskPlayers = (try? self.disk.load([Player].self, from: self.filename)) ?? []
            diskPlayers.sort { $0.lastUsed > $1.lastUsed }
            
            DispatchQueue.main.async {
                self.playersSubject.send(diskPlayers)
                completion?()
            }
        }
    }
    
    private func saveToCloud(completion: (() -> Void)? = nil) {
        let list = playersSubject.value.map { p in
            let id = CKRecord.ID(recordName: p.id)
            return (obj: p, recordID: id)
        }
        
        cloud.saveRecords(list) { _ in
            completion?()
        }
    }
    
    private func merge(cloudPlayers: [Player]) {
        var byID = Dictionary(uniqueKeysWithValues: playersSubject.value.map { ($0.id,$0) })
        for p in cloudPlayers { byID[p.id] = p }
        let merged = Array(byID.values).sorted { $0.lastUsed > $1.lastUsed }
        DispatchQueue.main.async {
            self.playersSubject.send(merged)
        }
    }
    
    private func savePlayersToDisk(_ list: [Player]) {
       try? self.disk.save(list, to: self.filename)
    }
    
    private func savePlayerToCloud(_ player: Player) {
        // And push just this one up to CloudKit
        let recordID = CKRecord.ID(recordName: player.id)
        cloud.saveRecord(player, recordID: recordID) { result in
            switch result {
            case .success:
                print("✓ pushed player \(player.name) to CloudKit")
            case .failure(let err):
                print("⚠️ failed to push \(player.name) to CloudKit:", err)
            }
        }
    }
    
    private func deletePlayerFromCloud(_ player: Player) {
        let rid = CKRecord.ID(recordName: player.id)
        cloud.deleteRecord(recordID: rid) { result in
            switch result {
            case .success:
                print("✓ deleted \(player.name) from CloudKit")
            case .failure(let err):
                print("⚠️ could not delete from CloudKit:", err)
            }
        }
    }
}

// MARK: - PlayerRepositoryProtocol
extension PlayerService: PlayerRepositoryProtocol {
    func reload() { loadLocalPlayers() }
    
    func getLastUsed() -> Player? { playersSubject.value.first }
    
    func save(_ player: Player) {
        print("save: \(player.name)")
        var list = playersSubject.value
        if let idx = list.firstIndex(where: { $0.id == player.id }) {
            list[idx].name     = player.name
            list[idx].lastUsed = Date()
        } else {
            list.append(player)
        }
        list.sort { $0.lastUsed > $1.lastUsed }
        playersSubject.send(list)
        savePlayersToDisk(list)
        savePlayerToCloud(player)
    }
    
    func delete(_ player: Player) {
        print("delete: \(player.name)")
        let updated = playersSubject.value.filter { $0.id != player.id }
        playersSubject.send(updated)
        savePlayersToDisk(updated)
        deletePlayerFromCloud(player)
    }
}
