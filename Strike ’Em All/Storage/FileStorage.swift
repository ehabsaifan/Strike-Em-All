//
//  FileStorage.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/10/25.
//

import Foundation

protocol Persistence {
  func save<T: Codable>(_ object: T, to filename: String) throws
  func load<T: Codable>(_ type: T.Type, from filename: String) throws -> T?
}

class FileStorage: Persistence {
    private let folder: URL
    
    init(folder: FileManager.SearchPathDirectory = .documentDirectory) {
        let fm = FileManager.default
        if let url = try? fm.url(for: folder,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true) {
            self.folder = url
        } else {
            self.folder = fm.temporaryDirectory
            print("⚠️ Couldn’t create documents folder, using temp:", folder)
        }
    }
    
    /// Save a Codable object to disk under the given filename.
    /// Prints any errors encountered before rethrowing.
    func save<T: Codable>(_ object: T, to filename: String) throws {
        let url = folder.appendingPathComponent(filename, isDirectory: false)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: [.atomic])
            print("FileStorage.save(\"\(filename)\") success")
        } catch {
            print("FileStorage.save(\"\(filename)\") error: \(error)")
            throw error
        }
    }
    
    /// Load and decode a Codable object from disk. Returns nil if file is missing.
    /// Prints any errors encountered before rethrowing.
    func load<T: Codable>(_ type: T.Type, from filename: String) throws -> T? {
        let url = folder.appendingPathComponent(filename, isDirectory: false)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("FileStorage.load(\"\(filename)\"): no file at path: \(url.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let object = try JSONDecoder().decode(type, from: data)
            print("FileStorage.load(\"\(filename)\") success")
            return object
        } catch {
            print("FileStorage.load(\"\(filename)\") error: \(error)")
            throw error
        }
    }
}
