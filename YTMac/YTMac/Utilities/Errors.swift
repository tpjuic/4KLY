//
//  Errors.swift
//  YTMac
//
//  Error definitions for YTMac application.
//  Validates Requirements: 11.1, 11.2, 11.3, 11.5
//

import Foundation

// MARK: - Binary Management Errors

/// Errors related to yt-dlp binary management (download, update, execution)
enum BinaryError: LocalizedError {
    case binaryNotFound
    case downloadFailed(reason: String)
    case updateFailed(reason: String)
    case executionFailed(exitCode: Int32, stderr: String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "yt-dlp not found. YTMac will attempt to download it automatically."
        case .downloadFailed(let reason):
            return "Failed to download yt-dlp: \(reason). Please check your internet connection."
        case .updateFailed(let reason):
            return "Failed to update yt-dlp: \(reason). Continuing with current version."
        case .executionFailed(_, let stderr):
            return parseExecutionError(stderr)
        case .permissionDenied:
            return "Permission denied. Please grant YTMac access to the Application Support directory."
        }
    }
    
    /// Parse yt-dlp execution error from stderr
    private func parseExecutionError(_ stderr: String) -> String {
        if stderr.contains("command not found") || stderr.contains("No such file") {
            return "yt-dlp binary not found or not executable."
        } else if stderr.contains("Permission denied") {
            return "Permission denied when executing yt-dlp."
        } else {
            return "Failed to execute yt-dlp. Please check the installation."
        }
    }
}

// MARK: - Download Execution Errors

/// Errors related to video download execution
enum DownloadError: LocalizedError {
    case unsupportedURL(url: String)
    case networkFailure
    case rateLimited
    case videoUnavailable(reason: String)
    case diskSpaceExhausted
    case invalidOutputPath(path: String)
    case timeout
    case ytdlpError(stderr: String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedURL(let url):
            return "This site is not supported for downloading: \(url)"
        case .networkFailure:
            return "Network error. Please check your internet connection and try again."
        case .rateLimited:
            return "YouTube rate limit reached. Please wait 15-30 minutes and try again."
        case .videoUnavailable(let reason):
            return "Video unavailable: \(reason)"
        case .diskSpaceExhausted:
            return "Insufficient disk space. Please free up space and try again."
        case .invalidOutputPath(let path):
            return "Invalid download location: \(path)"
        case .timeout:
            return "Download timed out. Please try again."
        case .ytdlpError(let stderr):
            return parseYtdlpError(stderr)
        }
    }
    
    /// Parse yt-dlp error output into user-friendly message
    /// Validates: Requirements 11.2, 11.3, 11.5
    private func parseYtdlpError(_ stderr: String) -> String {
        if stderr.contains("Unsupported URL") {
            return "This site is not supported for downloading."
        } else if stderr.contains("Unable to download webpage") {
            return "Network error. Please check your internet connection."
        } else if stderr.contains("Video unavailable") {
            return "This video is unavailable (it may be private, deleted, or restricted)."
        } else if stderr.contains("HTTP Error 403") {
            return "Access denied. This video may be geo-restricted or require authentication."
        } else if stderr.contains("HTTP Error 404") {
            return "Video not found. The URL may be incorrect or the video was removed."
        } else if stderr.contains("No space left on device") {
            return "Insufficient disk space. Please free up space and try again."
        } else {
            return "Download failed. Please try again or check the video URL."
        }
    }
}

// MARK: - Persistence Errors

/// Errors related to data persistence (SwiftData, file I/O)
enum PersistenceError: LocalizedError {
    case containerInitFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .containerInitFailed(let error):
            return "Failed to initialize storage: \(error.localizedDescription). Download history may not be saved."
        case .saveFailed(let error):
            return "Failed to save download to history: \(error.localizedDescription)."
        case .fetchFailed(let error):
            return "Failed to load download history: \(error.localizedDescription)."
        }
    }
}

// MARK: - Quality Gate Errors

/// Errors related to quality validation and premium feature gating
enum QualityGateError: LocalizedError {
    case qualityBlocked(prompt: UpgradePromptInfo)
    case invalidQuality
    
    var errorDescription: String? {
        switch self {
        case .qualityBlocked(let prompt):
            return prompt.message
        case .invalidQuality:
            return "Invalid quality selection."
        }
    }
}

// MARK: - File System Errors

/// Errors related to file system operations (directory creation, file access)
enum FileSystemError: LocalizedError {
    case applicationSupportNotFound
    case libraryDirectoryNotFound
    case directoryCreationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .applicationSupportNotFound:
            return "Could not locate Application Support directory"
        case .libraryDirectoryNotFound:
            return "Could not locate Library directory"
        case .directoryCreationFailed(let path):
            return "Failed to create directory at \(path)"
        }
    }
}

// MARK: - Supporting Types

/// Information for displaying upgrade prompt when premium features are blocked
struct UpgradePromptInfo {
    let message: String
    let upgradeURL: URL?
}
