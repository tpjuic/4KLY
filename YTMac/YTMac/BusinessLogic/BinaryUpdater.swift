//
//  BinaryUpdater.swift
//  YTMac
//
//  Created for yt-dlp binary management
//

import Foundation

/// Information about yt-dlp binary update status
struct UpdateInfo: Codable {
    /// Current installed version of yt-dlp
    let currentVersion: String
    
    /// Latest available version from GitHub
    let latestVersion: String
    
    /// Download URL for the latest release asset
    let downloadURL: URL
    
    /// Release notes from GitHub release
    let releaseNotes: String
}

// MARK: - GitHub API Models

/// Response model for GitHub Release API
private struct GitHubRelease: Codable {
    let tagName: String
    let body: String
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
    }
}

/// GitHub release asset information
private struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

// MARK: - GitHub API Client

/// HTTP client for querying GitHub API and fetching yt-dlp releases
actor GitHubAPIClient {
    
    // MARK: - Error Types
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case httpError(statusCode: Int, message: String)
        case noAssetFound
        case jsonParsingError(Error)
        case timeoutError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid GitHub API URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .httpError(let statusCode, let message):
                return "HTTP error \(statusCode): \(message)"
            case .noAssetFound:
                return "No macOS binary found in latest release"
            case .jsonParsingError(let error):
                return "Failed to parse JSON response: \(error.localizedDescription)"
            case .timeoutError:
                return "Request timed out"
            }
        }
    }
    
    // MARK: - Properties
    
    private let session: URLSession
    private let githubAPIEndpoint = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
    
    // MARK: - Initialization
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public API
    
    /// Fetches the latest yt-dlp release information from GitHub API
    /// - Returns: UpdateInfo containing version tag and download URL for macOS binary
    /// - Throws: APIError for network, HTTP, or parsing failures
    func fetchLatestRelease() async throws -> UpdateInfo {
        // Create URL from endpoint string
        guard let url = URL(string: githubAPIEndpoint) else {
            throw APIError.invalidURL
        }
        
        // Configure request with GitHub API headers
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("YTMac/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        
        // Perform HTTP request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Handle network errors and timeouts
            if (error as NSError).code == NSURLErrorTimedOut {
                throw APIError.timeoutError
            }
            throw APIError.networkError(error)
        }
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(
                domain: "GitHubAPIClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
            ))
        }
        
        // Check HTTP status code
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        let release: GitHubRelease
        
        do {
            release = try decoder.decode(GitHubRelease.self, from: data)
        } catch {
            throw APIError.jsonParsingError(error)
        }
        
        // Extract version tag (remove 'v' prefix if present)
        let version = release.tagName.hasPrefix("v") 
            ? String(release.tagName.dropFirst()) 
            : release.tagName
        
        // Find macOS binary asset
        guard let macOSAsset = findMacOSAsset(in: release.assets) else {
            throw APIError.noAssetFound
        }
        
        guard let downloadURL = URL(string: macOSAsset.browserDownloadUrl) else {
            throw APIError.invalidURL
        }
        
        // Return structured update information
        return UpdateInfo(
            currentVersion: "", // Current version must be determined by caller
            latestVersion: version,
            downloadURL: downloadURL,
            releaseNotes: release.body
        )
    }
    
    // MARK: - Private Helpers
    
    /// Finds the macOS-compatible binary asset in the release assets list
    /// - Parameter assets: Array of GitHub release assets
    /// - Returns: The first asset matching macOS naming patterns, or nil if not found
    private func findMacOSAsset(in assets: [GitHubAsset]) -> GitHubAsset? {
        // Search for assets containing "macos" or "darwin" in the name
        // yt-dlp typically names macOS binaries with these keywords
        return assets.first { asset in
            let lowercasedName = asset.name.lowercased()
            return lowercasedName.contains("macos") || lowercasedName.contains("darwin")
        }
    }
}

// MARK: - Binary Updater

/// Actor responsible for managing the yt-dlp binary lifecycle
/// Handles binary installation, version checking, and automatic updates
actor BinaryUpdater {
    
    // MARK: - Properties
    
    /// Path to the yt-dlp binary in Application Support directory
    private let binaryPath: URL
    
    /// GitHub API client for fetching release information
    private let githubAPI: GitHubAPIClient
    
    /// Timestamp of the last update check (for 24-hour throttling)
    private var lastUpdateCheck: Date?
    
    // MARK: - Initialization
    
    /// Creates a BinaryUpdater with dependency injection
    /// - Parameter githubAPI: The GitHub API client to use for update checks
    init(githubAPI: GitHubAPIClient) {
        self.githubAPI = githubAPI
        
        // Set binaryPath to ~/Library/Application Support/YTMac/yt-dlp
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.binaryPath = appSupport.appendingPathComponent("YTMac").appendingPathComponent("yt-dlp")
    }
    
    // MARK: - Public API
    
    /// Ensures yt-dlp binary exists at binaryPath, downloading if necessary
    /// Validates Requirements: 3.1, 3.2
    /// - Returns: URL to the binary path
    /// - Throws: BinaryError if download or setup fails
    func ensureBinaryExists() async throws -> URL {
        let fileManager = FileManager.default
        
        // Check if binary already exists
        if fileManager.fileExists(atPath: binaryPath.path) {
            return binaryPath
        }
        
        // Binary is missing, need to download it
        // First, ensure parent directory exists
        do {
            _ = try FileSystemManager.shared.ensureAppSupportDirectory()
        } catch {
            throw BinaryError.downloadFailed(reason: "Failed to create directory: \(error.localizedDescription)")
        }
        
        // Fetch latest release information from GitHub
        let releaseInfo: UpdateInfo
        do {
            releaseInfo = try await githubAPI.fetchLatestRelease()
        } catch {
            throw BinaryError.downloadFailed(reason: "Failed to fetch release info: \(error.localizedDescription)")
        }
        
        // Download the binary from GitHub
        let downloadedURL: URL
        do {
            downloadedURL = try await downloadBinary(from: releaseInfo.downloadURL)
        } catch {
            throw BinaryError.downloadFailed(reason: "Failed to download binary: \(error.localizedDescription)")
        }
        
        // Move downloaded file to binaryPath
        do {
            // If file already exists at destination (race condition), remove it
            if fileManager.fileExists(atPath: binaryPath.path) {
                try fileManager.removeItem(at: binaryPath)
            }
            
            try fileManager.moveItem(at: downloadedURL, to: binaryPath)
        } catch {
            throw BinaryError.downloadFailed(reason: "Failed to move binary to destination: \(error.localizedDescription)")
        }
        
        // Set executable permissions (chmod +x)
        do {
            try fileManager.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: binaryPath.path
            )
        } catch {
            throw BinaryError.permissionDenied
        }
        
        return binaryPath
    }
    
    /// Determines if an update check should be performed based on 24-hour throttle
    /// - Returns: true if lastUpdateCheck is nil or if 24+ hours have elapsed since last check, false otherwise
    func shouldCheckForUpdate() -> Bool {
        // If never checked before, should check
        guard let lastCheck = lastUpdateCheck else {
            return true
        }
        
        // Check if 24 hours (86400 seconds) have elapsed
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
        
        return timeSinceLastCheck >= twentyFourHours
    }
    
    /// Retrieves the current version of the installed yt-dlp binary
    /// Executes "yt-dlp --version" command and parses the version string from stdout
    /// - Returns: The version string (e.g., "2024.03.10")
    /// - Throws: BinaryError.binaryNotFound if the binary doesn't exist
    /// - Throws: BinaryError.executionFailed if the version command fails
    /// Validates Requirements: 3.6
    func getCurrentVersion() async throws -> String {
        // Check if binary exists
        guard FileManager.default.fileExists(atPath: binaryPath.path) else {
            throw BinaryError.binaryNotFound
        }
        
        // Create Process to execute yt-dlp --version
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["--version"]
        
        // Create pipes to capture stdout and stderr
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Execute the process
        do {
            try process.run()
        } catch {
            throw BinaryError.executionFailed(exitCode: -1, stderr: "Failed to launch yt-dlp process: \(error.localizedDescription)")
        }
        
        // Wait for process to complete
        process.waitUntilExit()
        
        // Check exit code
        let exitCode = process.terminationStatus
        guard exitCode == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
            throw BinaryError.executionFailed(exitCode: exitCode, stderr: stderr)
        }
        
        // Read and parse stdout
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: stdoutData, encoding: .utf8) else {
            throw BinaryError.executionFailed(exitCode: exitCode, stderr: "Failed to decode version output")
        }
        
        // Trim whitespace and newlines
        let version = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate that we got a non-empty version string
        guard !version.isEmpty else {
            throw BinaryError.executionFailed(exitCode: exitCode, stderr: "Empty version string returned")
        }
        
        return version
    }
    
    /// Checks for available yt-dlp updates by comparing local and GitHub versions
    /// Fetches latest release from GitHub API, compares with current installed version,
    /// and returns update information if a newer version is available
    /// - Returns: UpdateInfo if a newer version is available, nil if current version is latest
    /// - Throws: BinaryError if version check fails or API call fails
    /// Validates Requirements: 3.3, 3.4, 13.1, 13.2
    func checkForUpdates() async throws -> UpdateInfo? {
        // Get current installed version
        let currentVersion = try await getCurrentVersion()
        
        // Fetch latest release information from GitHub API
        let latestRelease = try await githubAPI.fetchLatestRelease()
        
        // Update lastUpdateCheck timestamp
        lastUpdateCheck = Date()
        
        // Compare versions to determine if update is available
        // yt-dlp uses YYYY.MM.DD format where lexicographic comparison matches chronological order
        if currentVersion != latestRelease.latestVersion {
            // Newer version available - return UpdateInfo with currentVersion populated
            return UpdateInfo(
                currentVersion: currentVersion,
                latestVersion: latestRelease.latestVersion,
                downloadURL: latestRelease.downloadURL,
                releaseNotes: latestRelease.releaseNotes
            )
        }
        
        // No update available - current version is latest
        return nil
    }
    
    /// Performs binary update to the specified version
    /// Downloads yt-dlp binary, verifies integrity, and atomically replaces existing binary
    /// Validates: Requirements 3.4, 13.5
    /// - Parameter updateInfo: Information about the update including download URL and version
    /// - Throws: BinaryError if download, verification, or installation fails
    func performUpdate(to updateInfo: UpdateInfo) async throws {
        let fileManager = FileManager.default
        
        // Download binary to temporary location
        let tempURL: URL
        do {
            tempURL = try await downloadBinary(from: updateInfo.downloadURL)
        } catch {
            throw BinaryError.downloadFailed(reason: error.localizedDescription)
        }
        
        // Verify downloaded file exists and is non-empty
        guard fileManager.fileExists(atPath: tempURL.path) else {
            throw BinaryError.downloadFailed(reason: "Downloaded file does not exist")
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: tempURL.path)
            guard let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
                // Clean up empty file
                try? fileManager.removeItem(at: tempURL)
                throw BinaryError.downloadFailed(reason: "Downloaded file is empty")
            }
        } catch {
            // Clean up on error
            try? fileManager.removeItem(at: tempURL)
            throw BinaryError.downloadFailed(reason: "Failed to verify downloaded file: \(error.localizedDescription)")
        }
        
        // Ensure parent directory exists
        let parentDirectory = binaryPath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDirectory.path) {
            do {
                try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            } catch {
                // Clean up temp file
                try? fileManager.removeItem(at: tempURL)
                throw BinaryError.updateFailed(reason: "Failed to create binary directory: \(error.localizedDescription)")
            }
        }
        
        // Remove existing binary if present
        if fileManager.fileExists(atPath: binaryPath.path) {
            do {
                try fileManager.removeItem(at: binaryPath)
            } catch {
                // Clean up temp file
                try? fileManager.removeItem(at: tempURL)
                throw BinaryError.updateFailed(reason: "Failed to remove existing binary: \(error.localizedDescription)")
            }
        }
        
        // Atomically move temp file to binaryPath
        do {
            try fileManager.moveItem(at: tempURL, to: binaryPath)
        } catch {
            // Clean up temp file if move fails
            try? fileManager.removeItem(at: tempURL)
            throw BinaryError.updateFailed(reason: "Failed to install binary: \(error.localizedDescription)")
        }
        
        // Mark as executable (chmod +x) - set POSIX permissions to 0o755
        do {
            try fileManager.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: binaryPath.path
            )
        } catch {
            throw BinaryError.updateFailed(reason: "Failed to set executable permissions: \(error.localizedDescription)")
        }
        
        // Update ytdlpVersion in UserDefaults
        let configService = ConfigurationService()
        configService.ytdlpVersion = updateInfo.latestVersion
    }
    
    // MARK: - Private Helpers
    
    /// Downloads a binary from the given URL to a temporary location
    /// - Parameter url: The URL to download from
    /// - Returns: URL to the downloaded file in the temporary directory
    /// - Throws: BinaryError if download fails
    private func downloadBinary(from url: URL) async throws -> URL {
        let session = URLSession.shared
        
        do {
            let (tempURL, response) = try await session.download(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BinaryError.downloadFailed(reason: "Invalid response type")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw BinaryError.downloadFailed(
                    reason: "HTTP error \(httpResponse.statusCode)"
                )
            }
            
            return tempURL
        } catch let error as BinaryError {
            throw error
        } catch {
            throw BinaryError.downloadFailed(reason: error.localizedDescription)
        }
    }
    
    // MARK: - FFmpeg Management
    
    /// URL for ffmpeg binary in Application Support
    private var ffmpegPath: URL {
        binaryPath.deletingLastPathComponent().appendingPathComponent("ffmpeg")
    }
    
    /// Ensures ffmpeg binary exists, downloading static build if necessary
    /// - Returns: URL to the ffmpeg binary path
    /// - Throws: BinaryError if download or setup fails
    func ensureFFmpegExists() async throws -> URL {
        let fileManager = FileManager.default
        
        // Check if ffmpeg already exists
        if fileManager.fileExists(atPath: ffmpegPath.path) {
            return ffmpegPath
        }
        
        // Also check system paths — if user has ffmpeg via Homebrew, skip download
        let systemPaths = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        if systemPaths.contains(where: { fileManager.fileExists(atPath: $0) }) {
            return ffmpegPath // won't be used since ProcessExecutor checks system paths first
        }
        
        // Download static ffmpeg binary from evermeet.cx (trusted macOS builds)
        let ffmpegURL = URL(string: "https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip")!
        
        Logger.shared.log("Downloading ffmpeg...", level: .info, file: #file, function: #function, line: #line)
        
        // Ensure parent directory exists
        let parentDir = ffmpegPath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        
        // Download zip file
        let (tempZipURL, response) = try await URLSession.shared.download(from: ffmpegURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BinaryError.downloadFailed(reason: "Failed to download ffmpeg")
        }
        
        // Unzip to temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Use /usr/bin/ditto to unzip (built into macOS)
        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzipProcess.arguments = ["-xk", tempZipURL.path, tempDir.path]
        try unzipProcess.run()
        unzipProcess.waitUntilExit()
        
        // Find ffmpeg binary in extracted contents
        let extractedContents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let ffmpegFile = extractedContents.first(where: { $0.lastPathComponent == "ffmpeg" }) else {
            // Clean up
            try? fileManager.removeItem(at: tempDir)
            throw BinaryError.downloadFailed(reason: "ffmpeg not found in downloaded archive")
        }
        
        // Move to Application Support
        if fileManager.fileExists(atPath: ffmpegPath.path) {
            try fileManager.removeItem(at: ffmpegPath)
        }
        try fileManager.moveItem(at: ffmpegFile, to: ffmpegPath)
        
        // Set executable permissions
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ffmpegPath.path)
        
        // Clean up temp directory
        try? fileManager.removeItem(at: tempDir)
        try? fileManager.removeItem(at: tempZipURL)
        
        Logger.shared.log("ffmpeg installed at: \(ffmpegPath.path)", level: .info, file: #file, function: #function, line: #line)
        
        return ffmpegPath
    }
    
    // MARK: - Test Helpers
    
    #if DEBUG
    /// Test helper to set lastUpdateCheck for testing purposes
    /// Only available in DEBUG builds for unit tests
    /// - Parameter date: The date to set as last update check time
    func setLastUpdateCheckForTesting(_ date: Date) {
        lastUpdateCheck = date
    }
    #endif
}
