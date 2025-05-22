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
    
    init(
         folder searchPath: FileManager.SearchPathDirectory = .documentDirectory,
         subfolder: String? = nil) {
           let fm = FileManager.default
           // 1. find the base URL (e.g. Documents)
           let baseURL = (try? fm.url(
               for: searchPath,
               in: .userDomainMask,
               appropriateFor: nil,
               create: true
           )) ?? fm.temporaryDirectory

           // 2. if they passed a subfolder, append it and create it
           if let sub = subfolder {
               let dir = baseURL.appendingPathComponent(sub, isDirectory: true)
               try? fm.createDirectory(
                   at: dir,
                   withIntermediateDirectories: true
               )
               self.folder = dir
           } else {
               // no subfolder: use Documents directly
               self.folder = baseURL
           }
       }

    /// Save a Codable object to disk under the given filename.
    /// Prints any errors encountered before rethrowing.
    func save<T: Codable>(_ object: T, to filename: String) throws {
        let url = folder.appendingPathComponent(filename, isDirectory: false)
        do {
            FileLogger.shared.log("Save success at \(url.path).", object: object, level: .verbose)
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: [.atomic])
        } catch {
            FileLogger.shared.log("Save \(url.path) error. \(error)", object: object, level: .error)
            throw error
        }
    }
    
    /// Load and decode a Codable object from disk. Returns nil if file is missing.
    /// Prints any errors encountered before rethrowing.
    func load<T: Codable>(_ type: T.Type, from filename: String) throws -> T? {
        let url = folder.appendingPathComponent(filename, isDirectory: false)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            FileLogger.shared.log("Filepath doesnt exist at \(url.path)", level: .debug)
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let object = try JSONDecoder().decode(type, from: data)
            FileLogger.shared.log("Load success from \(url.path).", object: object, level: .verbose)
            return object
        } catch {
            FileLogger.shared.log("Load \(type) from \(url.path) error. \(error)", level: .error)
            throw error
        }
    }
}
