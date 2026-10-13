//
//  DownloadJobViewModel.swift
//  4Kly
//
//  Created by 4Kly Developer
//

import Foundation

/// View-layer representation of a download job
/// Transforms the domain model (DownloadJob) into a format suitable for SwiftUI views
/// Requirements: 4.4, 5.5, 5.6
struct DownloadJobViewModel: Identifiable {
    let id: UUID
    let url: String
    let title: String
    let quality: VideoQuality
    let format: DownloadFormat
    let progress: DownloadProgress?
    let status: DownloadStatus
    
    // Video metadata
    let thumbnailURL: URL?
    let channelName: String?
    let duration: Int?
    let fileSize: Int64?
    
    /// Actual video height downloaded (e.g., 480, 720, 1080)
    /// May differ from requested quality for non-YouTube sites
    let actualHeight: Int?
    
    // Playlist grouping (nil for single-video downloads)
    let playlistGroupID: UUID?
    
    /// Initialize ViewModel from domain model
    /// - Parameter job: The domain model DownloadJob to transform
    init(from job: DownloadJob) {
        self.id = job.id
        self.url = job.url
        self.title = job.title
        self.quality = job.quality
        self.format = job.format
        self.progress = job.progress
        self.status = job.status
        self.thumbnailURL = job.thumbnailURL
        self.channelName = job.channelName
        self.duration = job.duration
        self.fileSize = job.fileSize
        self.actualHeight = job.actualHeight
        self.playlistGroupID = job.playlistGroupID
    }
    
    // MARK: - Computed Properties
    
    /// Title to display — title if non-empty, URL as fallback
    var displayTitle: String {
        title.isEmpty ? url : title
    }
    
    /// Quality string to display in the UI
    /// Uses actualHeight if available (for non-YouTube completed downloads)
    /// Falls back to requested quality for YouTube or in-progress downloads
    var displayQuality: String {
        // For completed downloads, show actual height if we have it
        if case .completed = status, let height = actualHeight {
            return "\(height)p"
        }
        // For in-progress or queued, show requested quality
        return quality.displayName.components(separatedBy: " ").first ?? "720p"
    }
    
    /// Whether the download is in indeterminate progress state
    /// Phase 1: percentage == 0 && speed == 0 → "Preparing download..."
    /// Phase 3: percentage == 1.0 && speed == 0 → "Merging..."
    var isIndeterminate: Bool {
        if case .active(let progress) = status {
            let isPreparingPhase = progress.percentage == 0 && progress.speed == 0
            let isMergingPhase = progress.percentage >= 1.0 && progress.speed == 0
            return isPreparingPhase || isMergingPhase
        }
        return false
    }
}
