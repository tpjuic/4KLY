//
//  ProcessExecutor.swift
//  4Kly
//
//  Created by 4Kly Team
//

import Foundation

/// Result of a yt-dlp subprocess execution.
struct ProcessResult: Codable {
    let exitCode: Int32
    let outputPath: URL?
    let error: String?
    let actualHeight: Int?
}

actor ProcessExecutor {
    
    private let binaryPath: URL
    private let progressParser = ProgressParser()
    private var activeProcesses: [Int32: Process] = [:]
    
    init(binaryPath: URL) {
        self.binaryPath = binaryPath
    }
    
    struct VideoMetadata {
        let title: String
        let thumbnailURL: URL?
        let channelName: String?
        let duration: Int?
        let fileSize: Int64?
        let actualHeight: Int?
    }
    
    func extractMetadata(url: String) async -> VideoMetadata? {
        if let oembedResult = await extractViaOEmbed(url: url) {
            return oembedResult
        }
        
        return await withTaskGroup(of: VideoMetadata?.self) { group in
            group.addTask {
                await self.extractMetadataJSON(url: url)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(30))
                return nil
            }
            for await result in group {
                group.cancelAll()
                return result
            }
            return nil
        }
    }
    
    private func extractViaOEmbed(url: String) async -> VideoMetadata? {
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
                duration: nil,
                fileSize: nil,
                actualHeight: nil
            )
        } catch {
            return nil
        }
    }
    
    private func extractMetadataJSON(url: String) async -> VideoMetadata? {
        guard FileManager.default.fileExists(atPath: binaryPath.path) else {
            Logger.shared.log("yt-dlp binary not found at: \(binaryPath.path)", level: .error)
            return nil
        }
        
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["--dump-json", "--no-download", "--no-playlist", url]
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        let exitCode: Int32 = await withCheckedContinuation { continuation in
            process.terminationHandler = { proc in
                continuation.resume(returning: proc.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                Logger.shared.log("Failed to run yt-dlp for metadata: \(error.localizedDescription)", level: .error)
                continuation.resume(returning: -1)
            }
        }
        
        if exitCode != 0 {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrStr = String(data: stderrData, encoding: .utf8) ?? ""
            Logger.shared.log("yt-dlp metadata extraction failed with exit code \(exitCode): \(stderrStr)", level: .warning)
            return nil
        }
        
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        
        guard !data.isEmpty else {
            Logger.shared.log("yt-dlp returned empty stdout for metadata", level: .warning)
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Logger.shared.log("Failed to parse yt-dlp JSON output", level: .warning)
            return nil
        }
        
        let title = json["title"] as? String ?? ""
        guard !title.isEmpty else {
            Logger.shared.log("yt-dlp JSON has empty title", level: .warning)
            return nil
        }
        
        let thumbnail = (json["thumbnail"] as? String).flatMap { URL(string: $0) }
        let channel = json["channel"] as? String ?? json["uploader"] as? String
        
        let duration: Int?
        if let d = json["duration"] as? Double {
            duration = Int(d)
        } else if let d = json["duration"] as? Int {
            duration = d
        } else {
            duration = nil
        }
        
        let fileSize: Int64?
        if let fs = json["filesize_approx"] as? Int64 {
            fileSize = fs
        } else if let fs = json["filesize_approx"] as? Double {
            fileSize = Int64(fs)
        } else if let fs = json["filesize"] as? Int64 {
            fileSize = fs
        } else {
            fileSize = nil
        }
        
        let actualHeight: Int?
        if let height = json["height"] as? Int {
            actualHeight = height
        } else if let formats = json["formats"] as? [[String: Any]] {
            let heights = formats.compactMap { $0["height"] as? Int }.filter { $0 > 0 }
            actualHeight = heights.max()
        } else {
            actualHeight = nil
        }
        
        Logger.shared.log("Extracted metadata for \(url): title=\(title), thumbnail=\(thumbnail?.absoluteString ?? "nil")", level: .debug)
        
        return VideoMetadata(
            title: title,
            thumbnailURL: thumbnail,
            channelName: channel,
            duration: duration,
            fileSize: fileSize,
            actualHeight: actualHeight
        )
    }
    
    func execute(
        url: String,
        quality: VideoQuality,
        format: DownloadFormat = .mp4,
        outputPath: URL,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> ProcessResult {
        let outputTemplate = outputPath.appendingPathComponent("%(title)s_%(height)sp.%(ext)s").path
        
        var arguments: [String]
        
        if format == .mp3 {
            arguments = [
                "--format", "bestaudio[ext=m4a]/bestaudio",
                "--extract-audio",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--no-playlist",
                "--output", outputTemplate,
                "--progress",
                "--newline",
                "--no-mtime",
                "--print", "after_move:%(height)s"
            ]
        } else {
            arguments = [
                "--format", quality.ytdlpFormat,
                "--merge-output-format", "mp4",
                "--no-playlist",
                "--output", outputTemplate,
                "--progress",
                "--newline",
                "--no-mtime",
                "--print", "after_move:%(height)s"
            ]
        }
        
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let bundledFFmpeg = appSupportDir.appendingPathComponent("4Kly").appendingPathComponent("ffmpeg").path
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
        
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = arguments
        
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        
        var actualOutputPath: URL?
        var actualHeight: Int?
        
        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading
        
        do {
            let progressParserRef = self.progressParser
            var allStdout = ""
            
            stdoutHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }
                
                if let output = String(data: data, encoding: .utf8) {
                    allStdout += output
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        if let progress = progressParserRef.parse(from: line) {
                            progressHandler(progress)
                        }
                    }
                }
            }
            
            var stderrData = Data()
            stderrHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stderrData.append(data)
                } else {
                    handle.readabilityHandler = nil
                }
            }
            
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
            
            let processID = process.processIdentifier
            activeProcesses.removeValue(forKey: processID)
            
            stdoutHandle.readabilityHandler = nil
            stderrHandle.readabilityHandler = nil
            
            let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""
            
            let lines = allStdout.components(separatedBy: .newlines)
            for line in lines.reversed() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if let height = Int(trimmed), height > 0 && height < 10000 {
                    actualHeight = height
                    break
                }
            }
            
            if exitCode == 0 {
                actualOutputPath = try await findDownloadedFile(in: outputPath)
            }
            
            if exitCode != 0 {
                throw parseDownloadError(from: stderrOutput, exitCode: exitCode)
            }
            
            return ProcessResult(
                exitCode: exitCode,
                outputPath: actualOutputPath,
                error: stderrOutput.isEmpty ? nil : stderrOutput,
                actualHeight: actualHeight
            )
            
        } catch let error as DownloadError {
            throw error
        } catch {
            throw DownloadError.ytdlpError(stderr: "Process execution failed: \(error.localizedDescription)")
        }
    }
    
    func cancel(processID: Int32) async throws {
        guard let process = activeProcesses[processID] else {
            throw DownloadError.ytdlpError(stderr: "Process not found: \(processID)")
        }
        process.terminate()
        activeProcesses.removeValue(forKey: processID)
    }
    
    private func findDownloadedFile(in directory: URL) async throws -> URL? {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let mediaExtensions = ["mp4", "webm", "mkv", "mp3", "m4a"]
            let videoFiles = contents.filter { url in
                mediaExtensions.contains(url.pathExtension.lowercased())
            }
            
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
