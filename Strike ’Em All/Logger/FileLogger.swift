//  FileLogger.swift
//  Strike ’Em All
//
//  Refactored: private internals in class, public API in extension

import UIKit

final class FileLogger {
    static let shared = FileLogger()

    // MARK: Configurable
    var minLevel: LogLevel = .debug
    var header = LogFileHeader()
    
    var isEnabled = true {
        didSet {
            if !isEnabled { clearAllLogs() }
        }
    }

    // MARK: Private storage
    private let maxFiles = 5
    private let maxSize = 500 * 1024  // 500KB per file
    private let baseFilename = "appStrikeEmAll.log"
    private let logQueue = DispatchQueue(label: "com.StrikeEmAll.FileLogger")

    private var handle: FileHandle!                       // current open handle
    private var lastHeaderData: Data?

    private var docsDir: URL {                           // logs folder
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Logs", isDirectory: true)
        ensureDirectory(at: dir)
        return dir
    }
    private var currentFile: URL { docsDir.appendingPathComponent(baseFilename) }
    private lazy var ubiqURL: URL? = {                   // iCloud sync folder
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents/Logs", isDirectory: true)
    }()

    private let dateFmt: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS'Z'"
        return df
    }()

    // MARK: Init
    private init() {
        hookCrashes()
        openLogFile()
        rotateIfNeeded()
    }

    // MARK: - Private Helpers

    private func ensureDirectory(at url: URL) {
        try? FileManager.default.createDirectory(at: url,
                                                withIntermediateDirectories: true)
    }

    private func fileSize(at url: URL) -> Int {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
    }

    private func openLogFile() {
        logQueue.sync {
            if !FileManager.default.fileExists(atPath: currentFile.path) {
                FileManager.default.createFile(atPath: currentFile.path, contents: nil)
            }
            handle = try? FileHandle(forUpdating: currentFile)
            handle.seekToEndOfFile()
            if fileSize(at: currentFile) == 0 {
                writeHeaderIfNeeded()
            }
        }
    }
    
    private func writeHeaderIfNeeded() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(header) else { return }
        // only write if this header != last one
        if data != lastHeaderData {
          lastHeaderData = data
          handle.write(data + "\n".data(using: .utf8)!)
        }
      }

    private func rotateIfNeeded() {
        guard fileSize(at: currentFile) >= maxSize else { return }
        handle.closeFile()

        // shift older rotated files
        for idx in stride(from: maxFiles - 1, through: 1, by: -1) {
            let src = rotatedFileURL(index: idx - 1)
            let dst = rotatedFileURL(index: idx)
            try? FileManager.default.removeItem(at: dst)
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.moveItem(at: src, to: dst)
            }
        }

        // rotate current to .0
        let firstRotated = rotatedFileURL(index: 0)
        syncToICloud(firstRotated)
        try? FileManager.default.moveItem(at: currentFile, to: firstRotated)

        // create fresh current
        FileManager.default.createFile(atPath: currentFile.path, contents: nil)
        handle = try? FileHandle(forUpdating: currentFile)
        handle.seekToEndOfFile()
        writeHeaderIfNeeded()
        syncToICloud(currentFile)
    }

    private func rotatedFileURL(index: Int) -> URL {
        let name = index == 0 ? baseFilename : "\(baseFilename).\(index)"
        return docsDir.appendingPathComponent(name)
    }

    private func syncToICloud(_ file: URL) {
        guard let destDir = ubiqURL else { return }
        do {
            ensureDirectory(at: destDir)
            let dest = destDir.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: file, to: dest)
        } catch {
            print("📤 iCloud sync failed:", error)
        }
    }

    private func clearAllLogs() {
        logQueue.sync {
            try? FileManager.default.removeItem(at: docsDir)
            ensureDirectory(at: docsDir)
            handle.closeFile()
            openLogFile()
        }
    }

    private func flush() {
        logQueue.sync { handle.synchronizeFile() }
    }

    private func hookCrashes() {
        NSSetUncaughtExceptionHandler { exception in
            let stack = exception.callStackSymbols.joined(separator: "\n")
            FileLogger.shared.log("Uncaught Exception: \(exception)\n\(stack)", level: .error)
        }
        for sig in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE] {
            signal(sig) { signal in
                FileLogger.shared.log("Crash signal: \(signal)", level: .error)
                FileLogger.shared.flush()
                exit(signal)
            }
        }
    }
    
    /// Internal helper to append + rotate
    private func writeLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        logQueue.async {
            self.handle.write(data)
            self.rotateIfNeeded()
        }
    }
}

// MARK: - Public API
extension FileLogger {
    /// All log files in Documents/Logs
    var allLogFiles: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: docsDir,
            includingPropertiesForKeys: nil
        )) ?? []
    }

    /// Share log files via UIActivityViewController
    func presentShare(from vc: UIViewController) {
        let urls = allLogFiles
        guard !urls.isEmpty else { return }
        let ac = UIActivityViewController(activityItems: urls,
                                          applicationActivities: nil)
        vc.present(ac, animated: true)
    }

    /// Log a simple text message
    func log(_ message: String, level: LogLevel = .info) {
        guard isEnabled && level >= minLevel else { return }
        let line = "[\(dateFmt.string(from: Date()))] [\(level.label)] \(message)\n"
        print("\(line)\n")
        writeLine(line)
    }

    /// Log any Codable object as JSON
    func log<T: Codable>(_ object: T, level: LogLevel = .debug) {
        guard isEnabled && level >= minLevel else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(object)
            if let body = String(data: data, encoding: .utf8) {
                let line = "[\(dateFmt.string(from: Date()))] [\(level.label)] \(body)\n"
                print("\(line)\n")
                writeLine(line)
            } else {
                log("Failed to convert data of \(T.self) to string", level: .error)
            }
        } catch {
            log("Failed to JSON-encode object of type \(T.self). \(error)", level: .error)
        }
    }
 
    /// Log a  text message and Codable object
    func log<T: Encodable>(_ message: String,
                         object: T,
                         level: LogLevel = .info) {
      guard isEnabled && level >= minLevel else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(object)
            if let body = String(data: data, encoding: .utf8) {
                let line = "[\(dateFmt.string(from: Date()))] [\(level.label)] \(message)! \(body)\n"
                print("\(line)\n")
                writeLine(line)
            } else {
                log("[\(dateFmt.string(from: Date()))] [\(level.label)] \(message)! Failed to convert data of \(T.self) to string\n", level: .error)
            }
        } catch {
            log("\(message)! Failed to JSON-encode object of type \(T.self). \(error)", level: .error)
        }
    }
    
    func start(minLevel: LogLevel,
               enabled: Bool,
               metadata: LogFileHeader) {
        print(isEnabled, minLevel)
        self.header = metadata
        self.minLevel = minLevel
        self.isEnabled = enabled
    }
}
