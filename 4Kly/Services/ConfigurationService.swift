//
//  ConfigurationService.swift
//  YTMac
//
//  Configuration service for managing application settings and preferences.
//  Implements Requirements 8.2, 8.3, 8.4, 10.1, 10.3
//

import Foundation

/// Service for managing application configuration and user preferences
class ConfigurationService {
    private let defaults = UserDefaults.standard
    
    // MARK: - Download Location
    
    /// The directory where downloaded videos are saved.
    /// Defaults to ~/Downloads on first access.
    /// Validates: Requirement 8.2, 8.4
    var downloadLocation: URL {
        get {
            if let path = defaults.string(forKey: UserDefaultsKey.downloadLocation.rawValue) {
                return URL(fileURLWithPath: path)
            }
            // Default to ~/Downloads on first access
            let defaultLocation = FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask
            )[0]
            return defaultLocation
        }
        set {
            defaults.set(newValue.path, forKey: UserDefaultsKey.downloadLocation.rawValue)
        }
    }
    
    // MARK: - Upgrade URL
    
    /// URL for the premium version upgrade page.
    /// Returns nil if not configured.
    /// Validates: Requirement 10.1, 10.3
    var upgradeURL: URL? {
        get {
            if let urlString = defaults.string(forKey: UserDefaultsKey.upgradeURL.rawValue) {
                return URL(string: urlString)
            }
            return nil
        }
        set {
            defaults.set(newValue?.absoluteString, forKey: UserDefaultsKey.upgradeURL.rawValue)
        }
    }
    
    // MARK: - Update Check Tracking
    
    /// Timestamp of the last yt-dlp update check.
    /// Returns nil if never checked.
    /// Validates: Requirement 10.3
    var lastUpdateCheck: Date? {
        get {
            defaults.object(forKey: UserDefaultsKey.lastUpdateCheck.rawValue) as? Date
        }
        set {
            defaults.set(newValue, forKey: UserDefaultsKey.lastUpdateCheck.rawValue)
        }
    }
    
    // MARK: - yt-dlp Version
    
    /// The currently installed yt-dlp version string.
    /// Returns nil if not set.
    var ytdlpVersion: String? {
        get {
            defaults.string(forKey: UserDefaultsKey.ytdlpVersion.rawValue)
        }
        set {
            defaults.set(newValue, forKey: UserDefaultsKey.ytdlpVersion.rawValue)
        }
    }
    
    // MARK: - Async Getters for Actor Compatibility
    
    /// Async getter for upgradeURL for use in actor contexts
    func getUpgradeURL() async -> URL? {
        return upgradeURL
    }
}
