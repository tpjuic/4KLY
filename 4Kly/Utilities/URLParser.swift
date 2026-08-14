//
//  URLParser.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

/// Parses multi-URL input strings for batch downloads
class URLParser {
    
    /// Parses multi-URL input, splitting on newlines and commas
    /// - Parameter input: The input string containing one or more URLs
    /// - Returns: Array of cleaned URL strings with empty entries removed
    func parse(_ input: String) -> [String] {
        // Split on both newlines and commas
        let separators = CharacterSet(charactersIn: ",\n")
        let components = input.components(separatedBy: separators)
        
        // Filter out empty strings after trimming whitespace, then clean each URL
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { cleanURL($0) }
    }
    
    /// Cleans a YouTube URL by removing playlist, tracking, and unnecessary parameters.
    /// Keeps only the video ID parameter for YouTube URLs.
    /// Non-YouTube URLs are returned unchanged.
    func cleanURL(_ url: String) -> String {
        guard var components = URLComponents(string: url) else { return url }
        guard let host = components.host?.lowercased() else { return url }
        
        // YouTube watch URLs — keep only ?v= parameter
        if (host.contains("youtube.com") || host.contains("youtube-nocookie.com")),
           components.path == "/watch",
           let queryItems = components.queryItems,
           let videoID = queryItems.first(where: { $0.name == "v" })?.value {
            components.queryItems = [URLQueryItem(name: "v", value: videoID)]
            return components.string ?? url
        }
        
        // YouTube shorts — strip query params entirely
        if (host.contains("youtube.com")), components.path.hasPrefix("/shorts/") {
            components.queryItems = nil
            return components.string ?? url
        }
        
        // youtu.be short links — strip query params (list, si, etc.)
        if host.contains("youtu.be") {
            components.queryItems = nil
            return components.string ?? url
        }
        
        // Other URLs — return as-is
        return url
    }
}
