//
//  VideoQuality.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

enum VideoQuality: String, Codable, Hashable, CaseIterable {
    case audio_only
    case standard360p
    case standard480p
    case standard720p
    case high1080p
    case high1440p
    case high4k
    
    var resolution: Int {
        switch self {
        case .audio_only: return 0
        case .standard360p: return 360
        case .standard480p: return 480
        case .standard720p: return 720
        case .high1080p: return 1080
        case .high1440p: return 1440
        case .high4k: return 2160
        }
    }
    
    var displayName: String {
        switch self {
        case .audio_only: return "Audio Only"
        case .standard360p: return "360p (Standard)"
        case .standard480p: return "480p (Standard)"
        case .standard720p: return "720p (Standard)"
        case .high1080p: return "1080p (Premium)"
        case .high1440p: return "1440p (Premium)"
        case .high4k: return "4K (Premium)"
        }
    }
    
    var ytdlpFormat: String {
        switch self {
        case .audio_only: return "bestaudio[ext=m4a]/bestaudio"
        case .standard360p: return "bestvideo[height<=360][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=360]+bestaudio/best[height<=360]"
        case .standard480p: return "bestvideo[height<=480][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=480]+bestaudio/best[height<=480]"
        case .standard720p: return "bestvideo[height<=720][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio/best[height<=720]"
        case .high1080p: return "bestvideo[height<=1080][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=1080]+bestaudio/best[height<=1080]"
        case .high1440p: return "bestvideo[height<=1440][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=1440]+bestaudio/best[height<=1440]"
        case .high4k: return "bestvideo[height<=2160][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=2160]+bestaudio/best[height<=2160]"
        }
    }
}
