//
//  DownloadProgress.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

struct DownloadProgress: Codable, Equatable {
    let percentage: Double        // 0.0 to 1.0
    let downloadedBytes: Int64
    let totalBytes: Int64
    let speed: Int64              // bytes per second
    let eta: TimeInterval         // seconds remaining
}
