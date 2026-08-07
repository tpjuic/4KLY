//
//  UserDefaultsKey.swift
//  YTMac
//
//  Created by YTMac Team
//

import Foundation

/// Keys for storing configuration values in UserDefaults
/// Requirements: 8.2, 8.4, 10.1, 10.3
enum UserDefaultsKey: String {
    /// The user's preferred download location path
    /// Requirement 8.2: Default download location configuration
    /// Requirement 8.4: Persist download location preference
    case downloadLocation = "app.ytmac.downloadLocation"
    
    /// The URL for the premium upgrade page
    /// Requirement 10.1: Store upgrade website URL
    /// Requirement 10.3: Allow upgrade URL updates without recompiling
    case upgradeURL = "app.ytmac.upgradeURL"
    
    /// Timestamp of the last yt-dlp update check
    /// Used to enforce 24-hour throttle on update checks
    case lastUpdateCheck = "app.ytmac.lastUpdateCheck"
    
    /// The current version of the installed yt-dlp binary
    /// Used for displaying version info and detecting updates
    case ytdlpVersion = "app.ytmac.ytdlpVersion"
    
    /// Whether the user has completed the first-launch onboarding flow
    /// Requirement 9.5: Persist onboarding completion state
    case hasCompletedOnboarding = "app.ytmac.hasCompletedOnboarding"
}
