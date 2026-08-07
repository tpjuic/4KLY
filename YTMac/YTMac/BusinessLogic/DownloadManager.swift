//
//  DownloadManager.swift
//  YTMac
//
//  Actor responsible for orchestrating download lifecycle, managing concurrent execution,
//  and coordinating with QualityGate and ProcessExecutor.
//  Implements Requirements: 1.3, 2.3, 2.4, 4.1, 5.1, 5.2, 5.3, 5.4, 14.2, 12.4
//

import Foundation
import UserNotifications

/// Actor responsible for orchestrating download lifecycle, managing concurrent execution,
/// and coordinating with QualityGate and ProcessExecutor.
///
/// Thread-safety is guaranteed by the actor model, ensuring that concurrent
/// download operations do not interfere with each other.
actor DownloadManager {
    
    // MARK: - Dependencies
    
    private let processExecutor: ProcessExecutor
    private let qualityGate: QualityGate
    private let historyStore: DownloadHistoryStore
    private let configService: ConfigurationService
    
    // MARK: - State
    
    /// Currently executing downloads mapped by job UUID
    private var activeDownloads: [UUID: DownloadJob] = [:]
    
    /// Queue of downloads waiting for execution slot
    private var downloadQueue: [DownloadJob] = []
    
    /// Maximum number of concurrent downloads
    private let maxConcurrentDownloads = 1
    
    /// AsyncStream for publishing download updates to ViewModels
    private var updateContinuation: AsyncStream<DownloadJob>.Continuation?
    private let updateStream: AsyncStream<DownloadJob>
    
    // MARK: - Initialization
    
    /// Creates a new DownloadManager with required dependencies
    ///
    /// - Parameters:
    ///   - processExecutor: Executor for running yt-dlp subprocesses
    ///   - qualityGate: Quality validation strategy (free vs premium)
    ///   - historyStore: Persistence service for download history
    ///   - configService: Configuration service for download location and settings
    init(
        processExecutor: ProcessExecutor,
        qualityGate: QualityGate,
        historyStore: DownloadHistoryStore,
        configService: ConfigurationService
    ) {
        self.processExecutor = processExecutor
        self.qualityGate = qualityGate
        self.historyStore = historyStore
        self.configService = configService
        
        // Create AsyncStream for publishing updates
        var continuation: AsyncStream<DownloadJob>.Continuation?
        self.updateStream = AsyncStream { cont in
            continuation = cont
        }
        self.updateContinuation = continuation
    }
    
    // MARK: - Public API
    
    /// Submits a single download job after quality validation.
    ///
    /// This method:
    /// 1. Validates quality through QualityGate
    /// 2. Creates a DownloadJob with unique UUID
    /// 3. Either starts execution immediately or queues the job
    /// 4. Publishes job creation event
    ///
    /// - Parameters:
    ///   - url: The video URL to download
    ///   - quality: The desired video quality
    ///   - format: The desired output format (MP4 or MP3)
    /// - Returns: UUID of the created download job
    /// - Throws: QualityGateError if quality validation fails
    ///
    /// Validates: Requirements 1.3, 2.3, 2.4, 4.1, 5.3
    func submitDownload(url: String, quality: VideoQuality, format: DownloadFormat = .mp4) async throws -> UUID {
        // Validate quality through QualityGate
        let validationResult = await qualityGate.validateQuality(quality)
        
        switch validationResult {
        case .allowed:
            // Get instant thumbnail for YouTube URLs (no network call needed)
            let thumbnail = instantThumbnailURL(from: url)
            
            // Create job immediately with URL and thumbnail (show instantly in UI)
            let job = DownloadJob(
                id: UUID(),
                url: url,
                title: "",
                quality: quality,
                format: format,
                status: .queued,
                progress: nil,
                createdAt: Date(),
                completedAt: nil,
                outputPath: nil,
                errorMessage: nil,
                thumbnailURL: thumbnail
            )
            
            // Check if we can start execution immediately
            if activeDownloads.count < maxConcurrentDownloads {
                // Show as active immediately with indeterminate progress
                var activeJob = job
                activeJob.status = .active(progress: DownloadProgress(
                    percentage: 0,
                    downloadedBytes: 0,
                    totalBytes: 0,
                    speed: 0,
                    eta: 0
                ))
                activeDownloads[job.id] = activeJob
                
                // Publish immediately so UI shows the card
                updateContinuation?.yield(activeJob)
                
                // Start execution in background (will fetch metadata then download)
                Task {
                    await executeDownload(activeJob)
                }
            } else {
                // Add to queue for later execution
                downloadQueue.append(job)
                
                // Publish job creation event (shows as queued)
                updateContinuation?.yield(job)
                
                // Fetch metadata in background so queued items show thumbnails
                let jobId = job.id
                Task {
                    await fetchAndUpdateMetadata(jobId: jobId, url: url)
                }
            }
            
            return job.id
            
        case .blocked(_, let upgradePrompt):
            // Quality validation failed, throw error with upgrade prompt
            throw QualityGateError.qualityBlocked(prompt: upgradePrompt)
        }
    }
    
    /// Submits multiple download jobs as a batch.
    ///
    /// This method iterates over the provided URLs and calls submitDownload for each.
    /// If a quality validation fails for one URL, the method continues processing
    /// remaining URLs and collects partial results rather than failing the entire batch.
    ///
    /// - Parameters:
    ///   - urls: Array of video URLs to download
    ///   - quality: The desired video quality for all downloads
    ///   - format: The desired output format (MP4 or MP3)
    /// - Returns: Array of UUIDs for successfully submitted download jobs
    /// - Throws: Does not throw - collects partial results on quality gate failures
    ///
    /// Validates: Requirements 5.1, 5.2
    func submitBatch(urls: [String], quality: VideoQuality, format: DownloadFormat = .mp4) async -> [UUID] {
        var submittedUUIDs: [UUID] = []
        
        for url in urls {
            do {
                let uuid = try await submitDownload(url: url, quality: quality, format: format)
                submittedUUIDs.append(uuid)
            } catch {
                // Log the error but continue processing remaining URLs
                // This allows partial batch submission when quality gate blocks some downloads
                Logger.shared.log(
                    "Failed to submit download for URL \(url): \(error.localizedDescription)",
                    level: .warning
                )
            }
        }
        
        return submittedUUIDs
    }
    
    /// Cancels an active or queued download job.
    ///
    /// - Parameter id: UUID of the download job to cancel
    /// - Throws: DownloadError if job not found or cancellation fails
    ///
    /// Validates: Requirements 4.7
    func cancelDownload(id: UUID) async throws {
        // Check if job is in active downloads
        if var job = activeDownloads[id] {
            // Cancel the process
            // Note: We need to track process IDs in executeDownload to support this
            job.status = .cancelled
            activeDownloads.removeValue(forKey: id)
            
            // Publish cancellation event
            updateContinuation?.yield(job)
            
            // Start next queued job
            await startNextInQueue()
        }
        // Check if job is in queue
        else if let queueIndex = downloadQueue.firstIndex(where: { $0.id == id }) {
            var job = downloadQueue.remove(at: queueIndex)
            job.status = .cancelled
            
            // Publish cancellation event
            updateContinuation?.yield(job)
        }
        else {
            throw DownloadError.ytdlpError(stderr: "Download job not found: \(id)")
        }
    }
    
    /// Gets the current status of a download job.
    ///
    /// - Parameter id: UUID of the download job
    /// - Returns: Current DownloadStatus or nil if not found
    func getDownloadStatus(id: UUID) async -> DownloadStatus? {
        if let job = activeDownloads[id] {
            return job.status
        }
        if let job = downloadQueue.first(where: { $0.id == id }) {
            return job.status
        }
        return nil
    }
    
    /// Gets all currently active downloads.
    ///
    /// - Returns: Array of active download jobs
    func getActiveDownloads() async -> [DownloadJob] {
        return Array(activeDownloads.values)
    }
    
    /// Provides access to the update stream for ViewModels.
    ///
    /// - Returns: AsyncStream of download job updates
    func getUpdateStream() -> AsyncStream<DownloadJob> {
        return updateStream
    }
    
    // MARK: - Private Methods
    
    /// Executes a download job using ProcessExecutor.
    ///
    /// - Parameter job: The download job to execute
    private func executeDownload(_ job: DownloadJob) async {
        var updatedJob = job
        
        // If title is still empty (oEmbed didn't work), try a quick oEmbed fetch only
        // Skip yt-dlp metadata extraction entirely — it's too slow with outdated versions
        if updatedJob.title.isEmpty {
            if let metadata = await processExecutor.extractMetadata(url: job.url) {
                updatedJob.title = metadata.title
                updatedJob.thumbnailURL = metadata.thumbnailURL ?? updatedJob.thumbnailURL
                updatedJob.channelName = metadata.channelName
                updatedJob.duration = metadata.duration
                updatedJob.fileSize = metadata.fileSize
                
                // Update UI with metadata
                activeDownloads[job.id] = updatedJob
                updateContinuation?.yield(updatedJob)
            }
        }
        
        // Update status to active
        updatedJob.status = .active(progress: DownloadProgress(
            percentage: 0.0,
            downloadedBytes: 0,
            totalBytes: 0,
            speed: 0,
            eta: 0
        ))
        activeDownloads[job.id] = updatedJob
        updateContinuation?.yield(updatedJob)
        
        // Get output directory from configuration
        let outputPath = configService.downloadLocation
        let jobId = job.id
        
        // Trigger folder permission early by checking directory access
        // This ensures the macOS permission dialog appears before download starts
        let fileManager = FileManager.default
        if !fileManager.isWritableFile(atPath: outputPath.path) {
            // Try to create a temporary file to trigger the permission dialog
            let tempFile = outputPath.appendingPathComponent(".ytmac_access_check")
            fileManager.createFile(atPath: tempFile.path, contents: nil)
            try? fileManager.removeItem(at: tempFile)
        }
        
        do {
            // Execute download with progress handler
            let result = try await processExecutor.execute(
                url: job.url,
                quality: job.quality,
                format: job.format,
                outputPath: outputPath,
                progressHandler: { [weak self] progress in
                    guard let self = self else { return }
                    
                    Task {
                        await self.handleProgressUpdate(jobId: jobId, progress: progress)
                    }
                }
            )
            
            // Handle completion — use updatedJob which has metadata
            await handleDownloadCompletion(updatedJob, result: result)
            
        } catch {
            // Convert error to ProcessResult with non-zero exit code
            let processResult = ProcessResult(
                exitCode: -1,
                outputPath: nil,
                error: error.localizedDescription
            )
            await handleDownloadCompletion(updatedJob, result: processResult)
        }
    }
    
    /// Handles progress updates from ProcessExecutor.
    ///
    /// - Parameters:
    ///   - jobId: UUID of the job being updated
    ///   - progress: The new progress information
    private func handleProgressUpdate(jobId: UUID, progress: DownloadProgress) async {
        guard var job = activeDownloads[jobId] else { return }
        
        // Never let progress go backwards — yt-dlp reports multiple streams
        // (video + audio for MP4) each with their own 0→100%.
        // Simple rule: only update if new percentage >= current percentage.
        if let currentProgress = job.progress {
            if progress.percentage < currentProgress.percentage && currentProgress.percentage > 0.1 {
                // Progress went backwards — this is a new stream, ignore it
                return
            }
        }
        
        job.progress = progress
        job.status = .active(progress: progress)
        activeDownloads[jobId] = job
        updateContinuation?.yield(job)
    }
    
    /// Handles completion of a download job, updating status and triggering next queued download.
    ///
    /// This method processes the result of a completed download execution:
    /// - If success (exitCode == 0): Updates job status to .completed with output path
    /// - If failure (exitCode != 0): Updates job status to .failed with error message
    /// - Saves the job to DownloadHistoryStore (with error handling - logs but doesn't fail)
    /// - Removes job from activeDownloads dictionary
    /// - Calls startNextInQueue() to process next queued download
    /// - Publishes completion event via AsyncStream
    ///
    /// - Parameters:
    ///   - job: The download job that completed execution
    ///   - result: The ProcessResult containing exit code, output path, and error information
    ///
    /// Validates: Requirements 4.5, 4.6, 6.1, 6.2
    private func handleDownloadCompletion(_ job: DownloadJob, result: ProcessResult) async {
        var updatedJob = job
        updatedJob.completedAt = Date()
        
        // Check result.exitCode to determine success or failure
        if result.exitCode == 0 {
            // Success: update job status to .completed with output path
            updatedJob.status = .completed(path: result.outputPath ?? configService.downloadLocation)
            updatedJob.outputPath = result.outputPath
        } else {
            // Failure: update job status to .failed with error message
            let errorMessage = result.error ?? "Download failed with exit code \(result.exitCode)"
            
            // Check for rate limiting and send system notification
            let lowercased = errorMessage.lowercased()
            if lowercased.contains("429") || lowercased.contains("too many requests") || lowercased.contains("sign in to confirm") || lowercased.contains("confirm you're not a bot") || lowercased.contains("rate limit") {
                sendRateLimitNotification()
                updatedJob.status = .failed(error: "YouTube rate limit reached. Please wait 15-30 minutes and try again.")
            } else {
                updatedJob.status = .failed(error: ErrorMessageTransformer().transform(ytdlpStderr: errorMessage))
            }
            updatedJob.errorMessage = errorMessage
        }
        
        // Save job to DownloadHistoryStore
        // Wrap in do-catch to log error but don't fail completion process
        do {
            try await MainActor.run {
                try historyStore.saveDownload(updatedJob)
            }
        } catch {
            // Log error but continue - history save failure shouldn't block completion
            Logger.shared.log(
                "Failed to save download to history: \(error.localizedDescription)",
                level: .error,
                file: #file,
                function: #function,
                line: #line
            )
        }
        
        // Remove job from activeDownloads
        activeDownloads.removeValue(forKey: job.id)
        
        // Publish completion event
        updateContinuation?.yield(updatedJob)
        
        // Call startNextInQueue() to process next queued download
        await startNextInQueue()
    }
    
    /// Starts the next queued job if slots are available.
    ///
    /// Validates: Requirements 5.4
    private func startNextInQueue() async {
        // Check if we have capacity and queued jobs
        guard activeDownloads.count < maxConcurrentDownloads,
              !downloadQueue.isEmpty else {
            return
        }
        
        // Dequeue first job
        let nextJob = downloadQueue.removeFirst()
        
        // Add to active downloads
        activeDownloads[nextJob.id] = nextJob
        
        // Start execution in background
        Task {
            await executeDownload(nextJob)
        }
    }
    
    /// Fetches metadata for a queued job and updates it in the queue.
    private func fetchAndUpdateMetadata(jobId: UUID, url: String) async {
        guard let metadata = await processExecutor.extractMetadata(url: url) else { return }
        
        // Update the job in the download queue
        if let index = downloadQueue.firstIndex(where: { $0.id == jobId }) {
            downloadQueue[index].title = metadata.title
            downloadQueue[index].thumbnailURL = metadata.thumbnailURL
            downloadQueue[index].channelName = metadata.channelName
            downloadQueue[index].duration = metadata.duration
            downloadQueue[index].fileSize = metadata.fileSize
            
            // Publish update so UI refreshes the queued card
            updateContinuation?.yield(downloadQueue[index])
        }
    }
    
    /// Sends a macOS system notification when YouTube rate limits the user
    private func sendRateLimitNotification() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            
            // Request permission if not already granted
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                try? await center.requestAuthorization(options: [.alert, .sound])
            }
            
            let content = UNMutableNotificationContent()
            content.title = "YouTube Rate Limit"
            content.body = "Too many downloads in a short time. Please wait 15-30 minutes before trying again."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "ytmac.ratelimit.\(UUID().uuidString)",
                content: content,
                trigger: nil // deliver immediately
            )
            
            try? await center.add(request)
        }
    }
    
    /// Extracts a YouTube thumbnail URL instantly from the video URL (no network call).
    /// Works for youtube.com/watch?v=ID, youtu.be/ID, youtube.com/shorts/ID patterns.
    private func instantThumbnailURL(from url: String) -> URL? {
        guard let components = URLComponents(string: url) else { return nil }
        
        var videoID: String?
        
        if let host = components.host?.lowercased() {
            if host.contains("youtube.com") || host.contains("youtube-nocookie.com") {
                if components.path.hasPrefix("/shorts/") {
                    // youtube.com/shorts/VIDEO_ID
                    videoID = String(components.path.dropFirst("/shorts/".count)).components(separatedBy: "/").first
                } else {
                    // youtube.com/watch?v=VIDEO_ID
                    videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
                }
            } else if host.contains("youtu.be") {
                // youtu.be/VIDEO_ID
                videoID = String(components.path.dropFirst())
            }
        }
        
        guard let id = videoID, !id.isEmpty else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
    }
}
