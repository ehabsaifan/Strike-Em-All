//
//  CrashLogSettingsViewModel.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/24/25.
//

import Combine
import MessageUI

@MainActor
class CrashLogSettingsViewModel: NSObject, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoggingEnabled: Bool {
        didSet {
            if !isLoggingEnabled {
                FileLogger.shared.log("Log enabled changed \(isLoggingEnabled)", level: .info)
            }
            SimpleDefaults.setValue(isLoggingEnabled, forKey: .loggingEnabled)
            FileLogger.shared.isEnabled = isLoggingEnabled
            if isLoggingEnabled {
                FileLogger.shared.log("Log enabled changed \(isLoggingEnabled)", level: .info)
            }
        }
    }
    
    @Published var logLevel: LogLevel {
        didSet {
            SimpleDefaults.setEnum(logLevel, forKey: .loggingLevel)
            FileLogger.shared.minLevel = logLevel
            FileLogger.shared.log("Log level changed \(logLevel)", level: .info)
        }
    }
    
    /// all log file URLs
    @Published private(set) var files: [URL] = []
    
    override init() {
        self.isLoggingEnabled = SimpleDefaults.getValue(forKey: .loggingEnabled) ?? false
        self.logLevel         = SimpleDefaults.getEnum(forKey: .loggingLevel) ?? .info
        super.init()
        FileLogger.shared.isEnabled = isLoggingEnabled
        FileLogger.shared.minLevel  = logLevel
        
        FileLogger.shared.filesChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.files = FileLogger.shared.allLogFiles
            }
            .store(in: &cancellables)
        files = FileLogger.shared.allLogFiles
    }
 
    func clearLogs() {
        FileLogger.shared.log("Clear log pressed", level: .info)
        FileLogger.shared.clearAllLogs()
    }
    
    // MARK: — Email logs
    
    func canSendMail() -> Bool {
        ComposeMailView.canSendMail()
    }
    
    func fileSizeKB(_ url: URL) -> Double {
        let bytes = (try? FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return Double(bytes) / 1_000.0
    }
}
