//
//  DownloadJob.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

struct DownloadJob: Identifiable, Codable {
    let id: UUID
    let url: String
    var title: String              // Extracted from yt-dlp metadata
    let quality: VideoQuality
    let format: DownloadFormat
    var status: DownloadStatus
    var progress: DownloadProgress?
    let createdAt: Date
    var completedAt: Date?
    var outputPath: URL?
    var errorMessage: String?
    
    // Video metadata (populated during extraction phase)
    var thumbnailURL: URL?
    var channelName: String?
    var duration: Int?             // Duration in seconds
    var fileSize: Int64?           // Estimated file size in bytes
    
    init(id: UUID = UUID(), url: String, title: String = "", quality: VideoQuality, format: DownloadFormat = .mp4, status: DownloadStatus = .queued, progress: DownloadProgress? = nil, createdAt: Date = Date(), completedAt: Date? = nil, outputPath: URL? = nil, errorMessage: String? = nil, thumbnailURL: URL? = nil, channelName: String? = nil, duration: Int? = nil, fileSize: Int64? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.quality = quality
        self.format = format
        self.status = status
        self.progress = progress
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.outputPath = outputPath
        self.errorMessage = errorMessage
        self.thumbnailURL = thumbnailURL
        self.channelName = channelName
        self.duration = duration
        self.fileSize = fileSize
    }
}
