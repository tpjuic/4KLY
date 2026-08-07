//
//  FileSystemManager.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

/// Manages file system operations for YTMac application directories
class FileSystemManager {
    static let shared = FileSystemManager()
    
    private init() {}
    
    /// Returns the path to ~/Library/Application Support/YTMac, creating it if necessary
    /// - Returns: URL pointing to the application support directory
    /// - Throws: FileSystemError if directory creation fails
    func ensureAppSupportDirectory() throws -> URL {
        let fileManager = FileManager.default
        
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw FileSystemError.applicationSupportNotFound
        }
        
        let ytmacDir = appSupport.appendingPathComponent("YTMac")
        
        if !fileManager.fileExists(atPath: ytmacDir.path) {
            try fileManager.createDirectory(
                at: ytmacDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        return ytmacDir
    }
    
    /// Returns the path to ~/Library/Logs/YTMac, creating it if necessary
    /// - Returns: URL pointing to the logs directory
    /// - Throws: FileSystemError if directory creation fails
    func ensureLogsDirectory() throws -> URL {
        let fileManager = FileManager.default
        
        guard let logsDir = fileManager.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first else {
            throw FileSystemError.libraryDirectoryNotFound
        }
        
        let logsBase = logsDir.appendingPathComponent("Logs")
        let ytmacLogsDir = logsBase.appendingPathComponent("YTMac")
        
        if !fileManager.fileExists(atPath: ytmacLogsDir.path) {
            try fileManager.createDirectory(
                at: ytmacLogsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        return ytmacLogsDir
    }
}
