//
//  ProcessExecutor.swift
//  YTMac
//
//  Created by YTMac Team
//

import Foundation

/// Result of a yt-dlp subprocess execution.
///
/// This struct encapsulates all information about the outcome of running
/// yt-dlp as a subprocess, including success/failure status, output location,
/// and any error messages captured from stderr.
struct ProcessResult: Codable {
    /// The exit code returned by the yt-dlp process.
    ///
    /// - A value of 0 indicates successful execution
    /// - Non-zero values indicate errors or failures
    let exitCode: Int32
    
    /// The file system path to the downloaded video file.
    ///
    /// This value is `nil` when:
    /// - The download failed (exitCode != 0)
    /// - The process was interrupted or cancelled
    /// - yt-dlp did not produce an output file
    let outputPath: URL?
    
    /// Error message captured from the process stderr stream.
    ///
    /// This value is `nil` when:
    /// - The download completed successfully (exitCode == 0)
    /// - No error output was produced by yt-dlp
    ///
    /// When populated, this typically contains yt-dlp error messages
    /// that can be transformed into user-friendly feedback.
    let error: String?
}

/// Actor responsible for executing yt-dlp as a subprocess with progress tracking.
///
/// ProcessExecutor handles the lifecycle of yt-dlp subprocess execution, including:
/// - Command construction with appropriate flags for quality and format
/// - Real-time progress parsing from stdout
/// - Error handling and stderr capture
/// - Process cancellation support
///
/// Thread-safety is guaranteed by the actor model, ensuring that concurrent
/// download operations do not interfere with each other.
///
/// Validates Requirements: 4.1, 4.2, 4.3, 4.4, 15.1, 15.2
actor ProcessExecutor {
    
    // MARK: - Properties
    
    /// Path to the yt-dlp binary executable
    private let binaryPath: URL
    
    /// Progress parser for extracting download progress from yt-dlp output
    private let progressParser = ProgressParser()
    
    /// Active process references for cancellation support
    private var activeProcesses: [Int32: Process] = [:]
    
    // MARK: - Initialization
    
    /// Creates a new ProcessExecutor with the specified yt-dlp binary path.
    /// - Parameter binaryPath: URL to the yt-dlp binary executable
    init(binaryPath: URL) {
        self.binaryPath = binaryPath
    }
    
    // MARK: - Public API
    
    /// Video metadata extracted from yt-dlp --dump-json
    struct VideoMetadata {
        let title: String
        let thumbnailURL: URL?
        let channelName: String?
        let duration: Int?
        let fileSize: Int64?
    }
    
    /// Extracts video metadata using YouTube oEmbed API (fast, reliable) with yt-dlp fallback.
    ///
    /// - Parameter url: The video URL to extract metadata from
    /// - Returns: VideoMetadata with title, thumbnail, channel, duration, and estimated size
    func extractMetadata(url: String) async -> VideoMetadata? {
        // Try YouTube oEmbed API first (fast and reliable, works even with old yt-dlp)
        if let oembedResult = await extractViaOEmbed(url: url) {
            return oembedResult
        }
        
        // For non-YouTube URLs, skip yt-dlp metadata (too slow/unreliable with outdated versions)
        // The download will still work, just without a title preview
        return nil
    }
    
    /// Extracts metadata via YouTube oEmbed API (no yt-dlp needed)
    private func extractViaOEmbed(url: String) async -> VideoMetadata? {
        // Only works for YouTube URLs
        guard url.contains("youtube.com") || url.contains("youtu.be") else { return nil }
        
        let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        guard let oembedURL = URL(string: "https://www.youtube.com/oembed?url=\(encodedURL)&format=json") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: oembedURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            let title = json["title"] as? String ?? ""
            let channel = json["author_name"] as? String
            let thumbnailURLStr = json["thumbnail_url"] as? String
            let thumbnail = thumbnailURLStr.flatMap { URL(string: $0) }
            
            guard !title.isEmpty else { return nil }
            
            return VideoMetadata(
                title: title,
                thumbnailURL: thumbnail,
                channelName: channel,
                duration: nil,  // oEmbed doesn't provide duration
                fileSize: nil   // oEmbed doesn't provide file size
            )
        } catch {
            return nil
        }
    }
    
    /// Fallback metadata extraction using --dump-json
    private func extractMetadataJSON(url: String) async -> VideoMetadata? {
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["--dump-json", "--no-download", url]
        
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            
            let exitCode = await withCheckedContinuation { continuation in
                process.terminationHandler = { proc in
                    continuation.resume(returning: proc.terminationStatus)
                }
            }
            
            guard exitCode == 0 else { return nil }
            
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            let title = json["title"] as? String ?? ""
            let thumbnail = (json["thumbnail"] as? String).flatMap { URL(string: $0) }
            let channel = json["channel"] as? String ?? json["uploader"] as? String
            let duration = json["duration"] as? Int
            let fileSize = json["filesize"] as? Int64 ?? json["filesize_approx"] as? Int64
            
            guard !title.isEmpty else { return nil }
            
            return VideoMetadata(
                title: title,
                thumbnailURL: thumbnail,
                channelName: channel,
                duration: duration,
                fileSize: fileSize
            )
        } catch {
            return nil
        }
    }
    
    /// Executes yt-dlp to download a video with specified quality and progress tracking.
    ///
    /// This method constructs and executes a yt-dlp command with the following flags:
    /// - `--format`: Quality selector based on VideoQuality.ytdlpFormat
    /// - `--merge-output-format mp4`: Force MP4 container (for video)
    /// - `--extract-audio --audio-format mp3`: Extract audio only (for MP3)
    /// - `--output`: Target file path
    /// - `--progress`: Enable progress output
    /// - `--newline`: Force newline-delimited progress (easier parsing)
    /// - `--no-mtime`: Don't set file modification time from video metadata
    /// - `--prefer-free-formats`: Prefer open codecs when available
    ///
    /// - Parameters:
    ///   - url: The video URL to download
    ///   - quality: The desired video quality
    ///   - format: The desired output format (MP4 or MP3)
    ///   - outputPath: The destination directory for the downloaded file
    ///   - progressHandler: Closure called on each progress update
    /// - Returns: ProcessResult containing exit code, output path, and any errors
    /// - Throws: DownloadError if execution fails or produces errors
    ///
    /// Validates: Requirements 4.1, 4.2, 4.3, 4.4, 15.1, 15.2
    func execute(
        url: String,
        quality: VideoQuality,
        format: DownloadFormat = .mp4,
        outputPath: URL,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> ProcessResult {
        // Construct yt-dlp command arguments
        let outputTemplate = outputPath.appendingPathComponent("%(title)s.%(ext)s").path
        
        var arguments: [String]
        
        if format == .mp3 {
            // Audio-only: extract audio and convert to MP3
            arguments = [
                "--format", "bestaudio[ext=m4a]/bestaudio",
                "--extract-audio",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--no-playlist",
                "--output", outputTemplate,
                "--progress",
                "--newline",
                "--no-mtime"
            ]
        } else {
            // Video: use quality-based format selection with MP4 container
            arguments = [
                "--format", quality.ytdlpFormat,
                "--merge-output-format", "mp4",
                "--no-playlist",
                "--output", outputTemplate,
                "--progress",
                "--newline",
                "--no-mtime"
            ]
        }
        
        // Add ffmpeg location if available (check app bundle, then common system paths)
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let bundledFFmpeg = appSupportDir.appendingPathComponent("YTMac").appendingPathComponent("ffmpeg").path
        let ffmpegPaths = [
            bundledFFmpeg,
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        if let ffmpegPath = ffmpegPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            let ffmpegDir = URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path
            arguments.append(contentsOf: ["--ffmpeg-location", ffmpegDir])
        }
        
        arguments.append(url)
        
        // Create and configure process
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = arguments
        
        // Setup stdout pipe for progress tracking
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        
        // Setup stderr pipe for error capture
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        
        // Track the actual output file path
        var actualOutputPath: URL?
        
        // File handles for reading process output
        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading
        
        // Launch process
        do {
            let progressParserRef = self.progressParser
            
            // Set up stdout reading for real-time progress
            stdoutHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }
                
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if let progress = progressParserRef.parse(from: line) {
                            progressHandler(progress)
                        }
                    }
                }
            }
            
            // Read stderr in background
            var stderrData = Data()
            stderrHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stderrData.append(data)
                } else {
                    handle.readabilityHandler = nil
                }
            }
            
            // Set termination handler BEFORE run() to avoid race condition
            let exitCode: Int32 = await withCheckedContinuation { continuation in
                process.terminationHandler = { proc in
                    continuation.resume(returning: proc.terminationStatus)
                }
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: -1)
                }
            }
            
            // Store/remove process reference
            let processID = process.processIdentifier
            activeProcesses.removeValue(forKey: processID)
            
            // Clean up handlers
            stdoutHandle.readabilityHandler = nil
            stderrHandle.readabilityHandler = nil
            
            let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""
            
            // Determine actual output path from successful download
            if exitCode == 0 {
                actualOutputPath = try await findDownloadedFile(in: outputPath)
            }
            
            // Handle non-zero exit codes
            if exitCode != 0 {
                throw parseDownloadError(from: stderrOutput, exitCode: exitCode)
            }
            
            return ProcessResult(
                exitCode: exitCode,
                outputPath: actualOutputPath,
                error: stderrOutput.isEmpty ? nil : stderrOutput
            )
            
        } catch let error as DownloadError {
            throw error
        } catch {
            throw DownloadError.ytdlpError(stderr: "Process execution failed: \(error.localizedDescription)")
        }
    }
    
    /// Cancels an active process by process ID.
    /// - Parameter processID: The process identifier to cancel
    /// - Throws: DownloadError if process cannot be cancelled
    func cancel(processID: Int32) async throws {
        guard let process = activeProcesses[processID] else {
            throw DownloadError.ytdlpError(stderr: "Process not found: \(processID)")
        }
        
        // Send SIGTERM for graceful termination
        process.terminate()
        
        // Remove from active processes
        activeProcesses.removeValue(forKey: processID)
    }
    
    // MARK: - Private Methods
    
    /// Finds the downloaded file in the output directory.
    ///
    /// Since yt-dlp uses template variables like %(title)s, we need to search
    /// for the most recently created file in the output directory.
    private func findDownloadedFile(in directory: URL) async throws -> URL? {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Filter for video/audio files (mp4, webm, mkv, mp3, m4a)
            let mediaExtensions = ["mp4", "webm", "mkv", "mp3", "m4a"]
            let videoFiles = contents.filter { url in
                mediaExtensions.contains(url.pathExtension.lowercased())
            }
            
            // Find the most recently created file
            let sortedFiles = videoFiles.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            return sortedFiles.first
        } catch {
            return nil
        }
    }
    
    /// Parses stderr output to create appropriate DownloadError.
    private func parseDownloadError(from stderr: String, exitCode: Int32) -> DownloadError {
        let lowercased = stderr.lowercased()
        
        if lowercased.contains("unsupported url") {
            return .unsupportedURL(url: "")
        } else if lowercased.contains("http error 429") || lowercased.contains("too many requests") || lowercased.contains("sign in to confirm") || lowercased.contains("confirm you're not a bot") {
            return .rateLimited
        } else if lowercased.contains("unable to download webpage") {
            return .networkFailure
        } else if lowercased.contains("video unavailable") {
            return .videoUnavailable(reason: "Video unavailable or private")
        } else if lowercased.contains("http error 403") {
            return .videoUnavailable(reason: "Access denied (geo-restricted or authentication required)")
        } else if lowercased.contains("http error 404") {
            return .videoUnavailable(reason: "Video not found")
        } else if lowercased.contains("no space left on device") {
            return .diskSpaceExhausted
        } else {
            return .ytdlpError(stderr: stderr)
        }
    }
}
