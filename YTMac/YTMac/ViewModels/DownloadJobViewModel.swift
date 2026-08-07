//
//  DownloadJobViewModel.swift
//  YTMac
//
//  Created by YTMac Developer
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
    }
    
    // MARK: - Computed Properties
    
    /// Title to display — title if non-empty, URL as fallback
    var displayTitle: String {
        title.isEmpty ? url : title
    }
    
    /// Whether the download is in indeterminate progress state (extracting info)
    var isIndeterminate: Bool {
        if case .active(let progress) = status {
            return progress.percentage == 0
        }
        return false
    }
}
