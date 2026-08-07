//
//  ProgressParser.swift
//  YTMac
//
//  Parses yt-dlp progress output strings to extract download progress information.
//  Validates Requirements: 4.3
//

import Foundation

/// Parses yt-dlp progress output to extract download progress information
class ProgressParser {
    
    /// Parses a yt-dlp progress output string and returns structured progress data
    /// - Parameter output: Raw yt-dlp output string (e.g., "[download]  12.3% of 45.67MiB at 1.23MiB/s ETA 00:32")
    /// - Returns: DownloadProgress struct if parsing succeeds, nil for invalid formats
    func parse(from output: String) -> DownloadProgress? {
        // Handle completion message: "[download] 100% of X.XXMiB in MM:SS"
        if let completionProgress = parseCompletionMessage(from: output) {
            return completionProgress
        }
        
        // Parse standard progress message: "[download]  12.3% of 45.67MiB at 1.23MiB/s ETA 00:32"
        return parseProgressMessage(from: output)
    }
    
    // MARK: - Private Parsing Methods
    
    /// Parses completion message format: "[download] 100% of X.XXMiB in MM:SS"
    private func parseCompletionMessage(from output: String) -> DownloadProgress? {
        let completionPattern = #"\[download\]\s+100(?:\.\d+)?%\s+of\s+([\d.]+)(\w+)\s+in\s+\d+:\d+"#
        
        guard let regex = try? NSRegularExpression(pattern: completionPattern, options: []),
              let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)) else {
            return nil
        }
        
        guard let totalSizeRange = Range(match.range(at: 1), in: output),
              let unitRange = Range(match.range(at: 2), in: output),
              let totalSize = Double(output[totalSizeRange]),
              let totalBytes = convertToBytes(size: totalSize, unit: String(output[unitRange])) else {
            return nil
        }
        
        // 100% complete - all fields reflect completion state
        return DownloadProgress(
            percentage: 1.0,
            downloadedBytes: totalBytes,
            totalBytes: totalBytes,
            speed: 0,
            eta: 0
        )
    }
    
    /// Parses standard progress message format: "[download]  12.3% of 45.67MiB at 1.23MiB/s ETA 00:32"
    private func parseProgressMessage(from output: String) -> DownloadProgress? {
        let progressPattern = #"\[download\]\s+(\d+\.?\d*)%\s+of\s+([\d.]+)(\w+)\s+at\s+([\d.]+)(\w+)/s\s+ETA\s+(\d+):(\d+)"#
        
        guard let regex = try? NSRegularExpression(pattern: progressPattern, options: []),
              let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)) else {
            return nil
        }
        
        // Extract captured groups
        guard match.numberOfRanges == 8,
              let percentageRange = Range(match.range(at: 1), in: output),
              let totalSizeRange = Range(match.range(at: 2), in: output),
              let totalUnitRange = Range(match.range(at: 3), in: output),
              let speedRange = Range(match.range(at: 4), in: output),
              let speedUnitRange = Range(match.range(at: 5), in: output),
              let etaMinutesRange = Range(match.range(at: 6), in: output),
              let etaSecondsRange = Range(match.range(at: 7), in: output) else {
            return nil
        }
        
        // Parse numeric values
        guard let percentage = Double(output[percentageRange]),
              let totalSize = Double(output[totalSizeRange]),
              let speedValue = Double(output[speedRange]),
              let etaMinutes = Int(output[etaMinutesRange]),
              let etaSeconds = Int(output[etaSecondsRange]) else {
            return nil
        }
        
        // Convert units to bytes
        let totalUnit = String(output[totalUnitRange])
        let speedUnit = String(output[speedUnitRange])
        
        guard let totalBytes = convertToBytes(size: totalSize, unit: totalUnit),
              let speedBytes = convertToBytes(size: speedValue, unit: speedUnit) else {
            return nil
        }
        
        // Calculate downloaded bytes from percentage and total
        let downloadedBytes = Int64(Double(totalBytes) * (percentage / 100.0))
        
        // Calculate ETA in seconds
        let eta = TimeInterval(etaMinutes * 60 + etaSeconds)
        
        // Convert percentage to 0.0-1.0 range
        let normalizedPercentage = percentage / 100.0
        
        return DownloadProgress(
            percentage: normalizedPercentage,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speed: speedBytes,
            eta: eta
        )
    }
    
    // MARK: - Unit Conversion
    
    /// Converts size with unit (MiB, KiB, GiB) to bytes
    /// - Parameters:
    ///   - size: Numeric size value
    ///   - unit: Unit string (e.g., "MiB", "KiB", "GiB", "B")
    /// - Returns: Size in bytes, or nil if unit is not recognized
    private func convertToBytes(size: Double, unit: String) -> Int64? {
        let multiplier: Double
        
        switch unit.lowercased() {
        case "b":
            multiplier = 1
        case "kib":
            multiplier = 1024
        case "mib":
            multiplier = 1024 * 1024
        case "gib":
            multiplier = 1024 * 1024 * 1024
        case "tib":
            multiplier = 1024 * 1024 * 1024 * 1024
        case "kb":
            multiplier = 1000
        case "mb":
            multiplier = 1000 * 1000
        case "gb":
            multiplier = 1000 * 1000 * 1000
        case "tb":
            multiplier = 1000 * 1000 * 1000 * 1000
        default:
            return nil
        }
        
        return Int64(size * multiplier)
    }
}
