//
//  SettingsViewModel.swift
//  YTMac
//
//  ViewModel for settings UI
//  Implements Requirements: 8.1, 8.3, 8.4, 3.6, 13.1
//

import Foundation
import SwiftUI
import AppKit

/// ViewModel for settings UI
/// Coordinates between settings view and configuration/update services
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current download location directory
    /// Requirements 8.1, 8.3: Provide settings panel for configuring download location
    @Published var downloadLocation: URL
    
    /// Currently installed yt-dlp version string
    /// Requirement 3.6: Display current yt-dlp version
    @Published var currentYtdlpVersion: String = "Checking..."
    
    /// Available update information, nil if no update available
    /// Requirement 13.1: Notify when yt-dlp updates are available
    @Published var availableYtdlpUpdate: UpdateInfo?
    
    /// Indicates if an update check is currently in progress
    /// Requirement 13.3: Display updating indicator in UI
    @Published var isCheckingForUpdates: Bool = false
    
    /// Indicates if a yt-dlp update is currently being installed
    /// Requirement 13.3: Display updating indicator in UI
    @Published var isUpdatingYtdlp: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let configService: ConfigurationService
    private let binaryUpdater: BinaryUpdater
    
    // MARK: - Initialization
    
    /// Initialize SettingsViewModel with dependencies
    ///
    /// - Parameters:
    ///   - configService: The configuration service for managing app settings
    ///   - binaryUpdater: The binary updater for yt-dlp management
    init(configService: ConfigurationService, binaryUpdater: BinaryUpdater) {
        self.configService = configService
        self.binaryUpdater = binaryUpdater
        
        // Initialize downloadLocation from configuration service
        // Requirement 8.4: Persist download location preference across launches
        self.downloadLocation = configService.downloadLocation
        
        // Requirement 3.3, 13.4: Automatically check for yt-dlp updates on launch
        // if 24 hours have elapsed since last check
        Task {
            // Wait a moment for binary download to complete on first launch
            try? await Task.sleep(for: .seconds(5))
            
            let shouldCheck = await binaryUpdater.shouldCheckForUpdate()
            if shouldCheck {
                await checkForYtdlpUpdates()
                // Auto-install if update is available
                if availableYtdlpUpdate != nil {
                    await installYtdlpUpdate()
                }
            } else {
                // Just get current version for display
                do {
                    let version = try await binaryUpdater.getCurrentVersion()
                    currentYtdlpVersion = version
                } catch {
                    currentYtdlpVersion = "Downloading..."
                    // Retry after binary download completes
                    try? await Task.sleep(for: .seconds(10))
                    if let version = try? await binaryUpdater.getCurrentVersion() {
                        currentYtdlpVersion = version
                        errorMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually check for yt-dlp updates
    /// Calls BinaryUpdater.checkForUpdates() and updates UI state
    /// Requirements 3.3, 3.4, 13.1, 13.2: Check for updates and display information
    func checkForYtdlpUpdates() async {
        // Set loading state
        isCheckingForUpdates = true
        errorMessage = nil
        
        do {
            // Call BinaryUpdater to check for updates
            let updateInfo = try await binaryUpdater.checkForUpdates()
            
            // Store update information in published property
            availableYtdlpUpdate = updateInfo
            
            // Update current version display
            if let updateInfo = updateInfo {
                // Update available - show current version from update info
                currentYtdlpVersion = updateInfo.currentVersion
            } else {
                // No update available - get current version
                let version = try await binaryUpdater.getCurrentVersion()
                currentYtdlpVersion = version
            }
            
        } catch {
            // Handle errors gracefully
            errorMessage = "Failed to check for updates: \(error.localizedDescription)"
            currentYtdlpVersion = "Error"
        }
        
        // Clear loading state
        isCheckingForUpdates = false
    }
    
    /// Present a directory picker and update download location
    /// Requirements 8.1, 8.3, 8.5: Allow user to select download location
    func selectDownloadLocation() async {
        let panel = NSOpenPanel()
        panel.title = "Select Download Location"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        let response = panel.runModal()
        
        guard response == .OK, let selectedURL = panel.url else {
            return
        }
        
        // Validate the selected path
        let validator = PathValidator()
        let result = validator.validate(selectedURL)
        
        switch result {
        case .valid:
            configService.downloadLocation = selectedURL
            downloadLocation = selectedURL
            errorMessage = nil
        case .invalid(let reason):
            errorMessage = "Invalid download location: \(reason)"
        }
    }
    
    /// Install available yt-dlp update
    /// Requirements 13.5: Download and install yt-dlp update
    func installYtdlpUpdate() async {
        guard let updateInfo = availableYtdlpUpdate else { return }
        
        isUpdatingYtdlp = true
        errorMessage = nil
        
        do {
            try await binaryUpdater.performUpdate(to: updateInfo)
            
            // Update displayed version
            currentYtdlpVersion = updateInfo.latestVersion
            availableYtdlpUpdate = nil
        } catch {
            errorMessage = "Failed to install update: \(error.localizedDescription)"
        }
        
        isUpdatingYtdlp = false
    }
}
