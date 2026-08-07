//
//  Logger.swift
//  YTMac
//
//  Created by YTMac Developer
//  Validates Requirements: 10.5, 11.6
//

import Foundation

/// Logging utility for YTMac application
/// Provides centralized logging to file and console with multiple log levels
class Logger {
    /// Shared singleton instance
    static let shared = Logger()
    
    /// Log levels for message categorization
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "com.ytmac.logger", qos: .utility)
    
    private init() {
        // Configure date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Initialize log file at ~/Library/Logs/YTMac/ytmac.log
        if let logsDir = try? FileSystemManager.shared.ensureLogsDirectory() {
            logFileURL = logsDir.appendingPathComponent("ytmac.log")
            
            // Create log file if it doesn't exist
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
            }
            
            // Open file handle for appending
            fileHandle = try? FileHandle(forWritingTo: logFileURL)
            fileHandle?.seekToEndOfFile()
        } else {
            print("Failed to initialize logger: could not access logs directory")
            logFileURL = URL(fileURLWithPath: "/dev/null") // Fallback
            fileHandle = nil
        }
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    /// Log a message with specified level and context
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level (debug, info, warning, error)
    ///   - file: Source file name (auto-filled)
    ///   - function: Function name (auto-filled)
    ///   - line: Line number (auto-filled)
    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = self.dateFormatter.string(from: Date())
            let fileName = (file as NSString).lastPathComponent
            let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)\n"
            
            // Write to file
            if let data = logMessage.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
            
            // Print to console in DEBUG builds
            #if DEBUG
            print(logMessage, terminator: "")
            #endif
        }
    }
    
    /// Convenience method for debug-level logging
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Convenience method for info-level logging
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Convenience method for warning-level logging
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Convenience method for error-level logging
    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}
