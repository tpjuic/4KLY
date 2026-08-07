//
//  DownloadStatus.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

enum DownloadStatus: Codable, Equatable {
    case queued
    case active(progress: DownloadProgress)
    case completed(path: URL)
    case failed(error: String)
    case cancelled
    
    var displayText: String {
        switch self {
        case .queued:
            return "Queued"
        case .active(let progress):
            return "Downloading \(Int(progress.percentage * 100))%"
        case .completed:
            return "Completed"
        case .failed(let error):
            return "Failed: \(error)"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var historyStatus: String {
        switch self {
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        default:
            return "unknown"
        }
    }
}
