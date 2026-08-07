//
//  HistoryViewModel.swift
//  YTMac
//
//  ViewModel for download history UI
//  Implements Requirements: 6.3
//

import Foundation
import SwiftUI

/// ViewModel for download history UI
/// Coordinates between history view and DownloadHistoryStore
@MainActor
class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of download history items to display
    @Published var historyItems: [DownloadHistoryItem] = []
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let historyStore: DownloadHistoryStore
    private let downloadManager: DownloadManager
    
    // MARK: - Initialization
    
    /// Initialize HistoryViewModel with dependencies
    ///
    /// - Parameters:
    ///   - historyStore: The download history store for persistence operations
    ///   - downloadManager: The download manager for initiating new downloads
    init(historyStore: DownloadHistoryStore, downloadManager: DownloadManager) {
        self.historyStore = historyStore
        self.downloadManager = downloadManager
    }
    
    // MARK: - Public Methods
    
    /// Load download history from the persistent store and update UI
    /// Requirements 6.3, 6.4: Display persisted download history
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            historyItems = try historyStore.fetchAll()
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
            historyItems = []
        }
    }
    
    /// Clear all download history from the persistent store and UI
    /// Requirement 6.5: Allow users to clear download history
    func clearHistory() async {
        do {
            try historyStore.deleteAll()
            historyItems = []
            errorMessage = nil
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }
    
    /// Re-download a video from the download history
    /// Extracts URL and quality from the history item and initiates a new download
    /// Requirement 6.6: Allow users to re-download items from download history
    ///
    /// - Parameter item: The download history item to re-download
    func redownload(item: DownloadHistoryItem) async {
        // Extract URL from history item
        let url = item.url
        
        // Parse quality string back to VideoQuality enum
        guard let quality = parseQuality(from: item.quality) else {
            errorMessage = "Unable to determine video quality from history"
            return
        }
        
        // Submit download through DownloadManager
        do {
            _ = try await downloadManager.submitDownload(url: url, quality: quality)
            errorMessage = nil
        } catch let error as QualityGateError {
            // Handle quality gate errors (e.g., premium content blocking)
            switch error {
            case .qualityBlocked(let prompt):
                errorMessage = prompt.message
            case .invalidQuality:
                errorMessage = "Invalid quality selection"
            }
        } catch {
            // Handle other errors
            errorMessage = "Failed to re-download: \(error.localizedDescription)"
        }
    }
    
    /// Delete a single item from download history
    /// Removes the item from persistent storage and updates the UI
    /// Requirement 6.5: Allow users to delete individual history entries
    ///
    /// - Parameter id: The unique identifier of the history item to delete
    func deleteItem(id: UUID) async {
        do {
            // Remove from persistent store
            try historyStore.deleteItem(id: id)
            
            // Remove from in-memory array to update UI
            historyItems.removeAll { $0.id == id }
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Helpers
    
    /// Parse quality display name back to VideoQuality enum
    /// Maps display names like "720p (Standard)" to VideoQuality.standard720p
    ///
    /// - Parameter displayName: The quality display name from history
    /// - Returns: Matching VideoQuality case, or nil if not found
    private func parseQuality(from displayName: String) -> VideoQuality? {
        // Find the VideoQuality case that matches the display name
        return VideoQuality.allCases.first { $0.displayName == displayName }
    }
}
