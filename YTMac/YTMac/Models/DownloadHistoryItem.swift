//
//  DownloadHistoryItem.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation
import SwiftData

@Model
class DownloadHistoryItem {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var quality: String
    @Attribute var format: String?
    var outputPath: String?
    var status: String
    var errorMessage: String?
    var createdAt: Date
    var completedAt: Date?
    
    /// Resolved format — returns stored value or defaults to "MP4" for legacy rows
    var resolvedFormat: String {
        format ?? "MP4"
    }
    
    init(id: UUID = UUID(), url: String, title: String, quality: String, format: String = "MP4", outputPath: String? = nil, status: String, errorMessage: String? = nil, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.quality = quality
        self.format = format
        self.outputPath = outputPath
        self.status = status
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
