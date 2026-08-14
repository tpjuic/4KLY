//
//  ErrorMessageTransformer.swift
//  YTMac
//
//  Transforms raw yt-dlp error messages into user-friendly strings.
//  Validates Requirements: 11.2, 11.3, 11.5
//

import Foundation

/// Transforms raw yt-dlp stderr output into user-friendly error messages
class ErrorMessageTransformer {
    
    /// Transforms raw yt-dlp stderr into a user-friendly error message
    /// - Parameter ytdlpStderr: The raw stderr output from yt-dlp
    /// - Returns: A user-friendly error message without raw technical details
    ///
    /// **Validates: Requirements 11.2, 11.3, 11.5**
    func transform(ytdlpStderr: String) -> String {
        let stderr = ytdlpStderr.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for common error patterns in order of specificity
        
        // Unsupported URL - Requirement 11.2
        if stderr.contains("Unsupported URL") {
            return "This site is not supported for downloading."
        }
        
        // Network errors - Requirement 11.3
        if stderr.contains("Unable to download webpage") {
            return "Network error. Please check your internet connection."
        }
        
        // Video unavailable - Requirement 11.2
        if stderr.contains("Video unavailable") {
            return "This video is unavailable (it may be private, deleted, or restricted)."
        }
        
        // HTTP errors - Requirement 11.5
        if stderr.contains("HTTP Error 403") || stderr.contains("403 Forbidden") {
            return "Access denied. This video may be geo-restricted or require authentication."
        }
        
        if stderr.contains("HTTP Error 404") || stderr.contains("404 Not Found") {
            return "Video not found. The URL may be incorrect or the video was removed."
        }
        
        if stderr.contains("HTTP Error 429") || stderr.contains("429 Too Many Requests") {
            return "Too many requests. Please wait a moment and try again."
        }
        
        if stderr.contains("HTTP Error 500") || stderr.contains("500 Internal Server Error") {
            return "Server error. The video site is experiencing issues. Please try again later."
        }
        
        if stderr.contains("HTTP Error 503") || stderr.contains("503 Service Unavailable") {
            return "Service temporarily unavailable. Please try again later."
        }
        
        // Generic HTTP error
        if stderr.contains("HTTP Error") {
            return "Network error occurred. Please try again."
        }
        
        // Disk space issues
        if stderr.contains("No space left on device") || stderr.contains("Disk quota exceeded") {
            return "Insufficient disk space. Please free up space and try again."
        }
        
        // Network timeout
        if stderr.contains("timed out") || stderr.contains("timeout") {
            return "Connection timed out. Please check your internet connection and try again."
        }
        
        // SSL/TLS errors
        if stderr.contains("SSL") || stderr.contains("certificate") {
            return "Secure connection error. Please check your internet connection."
        }
        
        // Private/Premium content
        if stderr.contains("requires payment") || stderr.contains("premium") || stderr.contains("members-only") {
            return "This content requires a subscription or payment on the source site."
        }
        
        // Geo-restriction
        if stderr.contains("not available in your country") || stderr.contains("geo-restricted") {
            return "This video is not available in your region."
        }
        
        // Age restriction
        if stderr.contains("age") && stderr.contains("restricted") {
            return "This video is age-restricted and cannot be downloaded."
        }
        
        // Live stream
        if stderr.contains("live") && (stderr.contains("stream") || stderr.contains("broadcast")) {
            return "Live streams cannot be downloaded while they are ongoing."
        }
        
        // Generic fallback - Requirement 11.5
        // Return a generic message without exposing raw technical details
        if !stderr.isEmpty {
            return "Download failed. Please verify the URL and try again."
        }
        
        // Empty stderr
        return "An unknown error occurred."
    }
}
