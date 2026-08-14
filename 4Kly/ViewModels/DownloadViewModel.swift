//
//  DownloadViewModel.swift
//  YTMac
//
//  ViewModel for download management UI
//  Implements Requirements: 1.1, 2.2, 4.4, 4.7, 5.5, 5.6, 10.2, 10.5
//

import Foundation
import SwiftUI
import AppKit

/// ViewModel for download management UI
/// Coordinates between UI and DownloadManager, transforms domain models to view models
@MainActor
class DownloadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// User input for video URL(s)
    @Published var urlInput: String = ""
    
    /// Currently selected video quality
    @Published var selectedQuality: VideoQuality = .standard720p
    
    /// Currently selected output format
    @Published var selectedFormat: DownloadFormat = .mp4
    
    /// Available quality options for the current video
    @Published var availableQualities: [VideoQuality] = []
    
    /// Currently active downloads
    @Published var activeDownloads: [DownloadJobViewModel] = []
    
    /// Queued downloads waiting for execution
    @Published var queuedDownloads: [DownloadJobViewModel] = []
    
    /// Completed/failed/cancelled downloads (visible in Downloads section)
    @Published var completedDownloads: [DownloadJobViewModel] = []
    
    /// Whether to show the upgrade prompt dialog
    @Published var showUpgradePrompt: Bool = false
    
    /// Information for the upgrade prompt
    @Published var upgradePromptInfo: UpgradePromptInfo?
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// Count of currently active downloads for sidebar badge
    var activeDownloadCount: Int {
        activeDownloads.count
    }
    
    // MARK: - Dependencies
    
    private let downloadManager: DownloadManager
    
    // MARK: - Initialization
    
    /// Initialize DownloadViewModel with dependencies
    ///
    /// - Parameter downloadManager: The download manager actor for coordinating downloads
    init(downloadManager: DownloadManager) {
        self.downloadManager = downloadManager
        
        // Subscribe to DownloadManager updates
        Task {
            await subscribeToDownloadUpdates()
        }
    }
    
    // MARK: - Public Methods
    
    /// Submit download(s) based on current URL input and quality selection.
    ///
    /// This method:
    /// 1. Validates urlInput using URLValidator
    /// 2. Parses URLs using URLParser (handles multi-URL input)
    /// 3. Calls DownloadManager.submitDownload for single URL
    /// 4. Calls DownloadManager.submitBatch for multiple URLs
    /// 5. Handles QualityGateError by showing upgrade prompt
    /// 6. Handles other errors by setting errorMessage
    /// 7. Clears urlInput on success
    ///
    /// Validates: Requirements 1.2, 1.3, 1.4, 2.3, 5.1
    func submitDownload() async {
        // Clear previous error state
        errorMessage = nil
        showUpgradePrompt = false
        
        // Validate URL input
        let validator = URLValidator()
        let validationResult = validator.validate(urlInput)
        
        guard validationResult == .valid else {
            errorMessage = "Please enter a valid URL"
            return
        }
        
        // Parse URLs (handles single and multi-URL input)
        let parser = URLParser()
        let urls = parser.parse(urlInput)
        
        guard !urls.isEmpty else {
            errorMessage = "Please enter a valid URL"
            return
        }
        
        do {
            // When MP3 format is selected, force audio_only quality
            let effectiveQuality: VideoQuality = selectedFormat.isAudioOnly ? .audio_only : selectedQuality
            
            if urls.count == 1 {
                // Single URL submission
                _ = try await downloadManager.submitDownload(url: urls[0], quality: effectiveQuality, format: selectedFormat)
            } else {
                // Batch URL submission
                _ = await downloadManager.submitBatch(urls: urls, quality: effectiveQuality, format: selectedFormat)
            }
            
            // Clear input on success
            urlInput = ""
        } catch let error as QualityGateError {
            // Show upgrade prompt for quality gate blocks
            if case .qualityBlocked(let promptInfo) = error {
                showUpgradePrompt = true
                upgradePromptInfo = promptInfo
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Open the upgrade URL in the default browser
    ///
    /// Called when user clicks upgrade button in the premium quality prompt.
    /// Opens the upgradeURL from upgradePromptInfo using NSWorkspace.
    /// Logs the interaction for analytics purposes.
    ///
    /// Validates: Requirements 10.2, 10.5
    func openUpgradeURL() {
        // Get the upgrade URL from prompt info
        guard let upgradeURL = upgradePromptInfo?.upgradeURL else {
            Logger.shared.warning("openUpgradeURL called but upgradeURL is nil")
            return
        }
        
        // Log the upgrade prompt interaction (Requirement 10.5)
        Logger.shared.info("User clicked upgrade prompt - Opening URL: \(upgradeURL.absoluteString)")
        
        // Open URL in default browser using NSWorkspace (Requirement 10.2)
        NSWorkspace.shared.open(upgradeURL)
    }
    
    /// Cancel an active or queued download
    ///
    /// This method delegates to DownloadManager to cancel the download.
    /// Handles errors gracefully by setting errorMessage.
    ///
    /// - Parameter id: UUID of the download job to cancel
    ///
    /// Validates: Requirements 4.7
    func cancelDownload(id: UUID) async {
        do {
            try await downloadManager.cancelDownload(id: id)
        } catch {
            // Set error message for user display
            errorMessage = "Failed to cancel download: \(error.localizedDescription)"
            
            // Log error for debugging
            Logger.shared.log(
                "Failed to cancel download \(id): \(error.localizedDescription)",
                level: .error,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Subscribe to DownloadManager AsyncStream for reactive updates
    private func subscribeToDownloadUpdates() async {
        let stream = await downloadManager.getUpdateStream()
        
        for await job in stream {
            // Transform DownloadJob to DownloadJobViewModel
            let viewModel = DownloadJobViewModel(from: job)
            
            // Update appropriate list based on status
            switch job.status {
            case .queued:
                updateQueuedDownloads(with: viewModel)
            case .active:
                updateActiveDownloads(with: viewModel)
            case .completed, .failed, .cancelled:
                moveToCompleted(viewModel)
            }
        }
    }
    
    /// Update queued downloads list with new or updated job
    private func updateQueuedDownloads(with viewModel: DownloadJobViewModel) {
        if let index = queuedDownloads.firstIndex(where: { $0.id == viewModel.id }) {
            queuedDownloads[index] = viewModel
        } else {
            queuedDownloads.append(viewModel)
        }
    }
    
    /// Update active downloads list with new or updated job
    private func updateActiveDownloads(with viewModel: DownloadJobViewModel) {
        // Remove from queued if it was there
        queuedDownloads.removeAll { $0.id == viewModel.id }
        
        // Update or add to active
        if let index = activeDownloads.firstIndex(where: { $0.id == viewModel.id }) {
            activeDownloads[index] = viewModel
        } else {
            activeDownloads.append(viewModel)
        }
    }
    
    /// Move a finished download from active to completed list (stays visible in Downloads)
    private func moveToCompleted(_ viewModel: DownloadJobViewModel) {
        activeDownloads.removeAll { $0.id == viewModel.id }
        queuedDownloads.removeAll { $0.id == viewModel.id }
        
        if let index = completedDownloads.firstIndex(where: { $0.id == viewModel.id }) {
            completedDownloads[index] = viewModel
        } else {
            completedDownloads.insert(viewModel, at: 0)
        }
    }
}
