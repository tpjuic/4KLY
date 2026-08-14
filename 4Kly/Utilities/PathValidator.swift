//
//  PathValidator.swift
//  YTMac
//
//  Created by YTMac Developer
//  Validates Requirements: 8.3, 11.4
//

import Foundation

/// Validates download paths for directory existence and write permissions
class PathValidator {
    
    /// Validates whether a directory path is writable
    /// - Parameter url: The directory URL to validate
    /// - Returns: PathValidationResult indicating whether the path is valid
    func validate(_ url: URL) -> PathValidationResult {
        let fileManager = FileManager.default
        let path = url.path
        
        // Check if path exists
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        
        guard exists else {
            return .invalid(reason: "Directory does not exist: \(path)")
        }
        
        // Check if path is a directory
        guard isDirectory.boolValue else {
            return .invalid(reason: "Path is not a directory: \(path)")
        }
        
        // Check if directory is writable
        guard fileManager.isWritableFile(atPath: path) else {
            return .invalid(reason: "Directory is not writable: \(path)")
        }
        
        return .valid
    }
}

/// Result of path validation
enum PathValidationResult {
    case valid
    case invalid(reason: String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let reason) = self {
            return reason
        }
        return nil
    }
}
