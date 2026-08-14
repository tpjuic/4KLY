//
//  DownloadFormat.swift
//  YTMac
//
//  Output format selection for downloads (MP4 video or MP3 audio-only)
//

import Foundation

/// The output format for a download.
///
/// MP4 downloads the video with audio merged into an MP4 container.
/// MP3 extracts audio only and converts to MP3 format.
enum DownloadFormat: String, Codable, Hashable, CaseIterable {
    case mp4
    case mp3
    
    var displayName: String {
        switch self {
        case .mp4: return "MP4"
        case .mp3: return "MP3"
        }
    }
    
    /// SF Symbol name for the format
    var iconName: String {
        switch self {
        case .mp4: return "film"
        case .mp3: return "music.note"
        }
    }
    
    /// Whether this format is audio-only
    var isAudioOnly: Bool {
        self == .mp3
    }
}
