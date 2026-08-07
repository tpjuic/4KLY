//
//  YTMacApp.swift
//  YTMac
//
//  Created by YTMac Developer
//

import SwiftUI
import SwiftData

// MARK: - App Delegate

/// Handles application lifecycle events including binary verification on launch
/// and graceful download cancellation on termination.
/// Validates Requirements: 3.1, 3.2, 3.3, 14.3
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    /// The BinaryUpdater instance used for binary existence verification
    var binaryUpdater: BinaryUpdater?
    
    /// The DownloadManager instance used for graceful termination
    var downloadManager: DownloadManager?
    
    /// Indicates whether the binary exists and is ready for use
    @Published var binaryReady: Bool = false
    
    /// Error message if binary verification fails, surfaced to the UI as an alert
    @Published var binaryError: String?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure yt-dlp binary exists on launch
        // Validates Requirements: 3.1, 3.2
        Task { @MainActor in
            await ensureBinaryOnLaunch()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cancel active downloads gracefully on termination
        // Validates Requirement: 14.3
        Task {
            await cancelActiveDownloadsOnTermination()
        }
    }
    
    // MARK: - Private Methods
    
    /// Ensures yt-dlp binary exists, downloading if necessary.
    /// Logs the result and updates published state for UI feedback.
    @MainActor
    private func ensureBinaryOnLaunch() async {
        guard let updater = binaryUpdater else {
            Logger.shared.log(
                "BinaryUpdater not configured in AppDelegate",
                level: .warning,
                file: #file,
                function: #function,
                line: #line
            )
            return
        }
        
        do {
            let binaryURL = try await updater.ensureBinaryExists()
            binaryReady = true
            binaryError = nil
            Logger.shared.log(
                "yt-dlp binary verified at: \(binaryURL.path)",
                level: .info,
                file: #file,
                function: #function,
                line: #line
            )
            
            // Also ensure ffmpeg exists for merging video+audio
            do {
                _ = try await updater.ensureFFmpegExists()
            } catch {
                // Non-fatal — downloads may still work without ffmpeg for some formats
                Logger.shared.log(
                    "ffmpeg not available: \(error.localizedDescription). Some downloads may fail to merge.",
                    level: .warning,
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        } catch {
            binaryReady = false
            binaryError = error.localizedDescription
            Logger.shared.log(
                "Failed to ensure yt-dlp binary exists: \(error.localizedDescription)",
                level: .error,
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
    
    /// Cancels any active downloads gracefully during app termination.
    private func cancelActiveDownloadsOnTermination() async {
        guard let manager = downloadManager else { return }
        
        let activeDownloads = await manager.getActiveDownloads()
        
        guard !activeDownloads.isEmpty else { return }
        
        Logger.shared.log(
            "App terminating - cancelling \(activeDownloads.count) active download(s)",
            level: .info,
            file: #file,
            function: #function,
            line: #line
        )
        
        for download in activeDownloads {
            do {
                try await manager.cancelDownload(id: download.id)
            } catch {
                Logger.shared.log(
                    "Failed to cancel download \(download.id): \(error.localizedDescription)",
                    level: .warning,
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
        }
    }
}

// MARK: - Main App

@main
struct YTMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let modelContainer: ModelContainer
    
    // Services
    private let configService: ConfigurationService
    private let binaryUpdater: BinaryUpdater
    
    // Business Logic
    private let downloadManager: DownloadManager
    
    // ViewModels
    @StateObject private var downloadViewModel: DownloadViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    /// Controls display of the binary error alert
    @State private var showBinaryErrorAlert: Bool = false
    
    init() {
        // Initialize ModelContainer
        let container: ModelContainer
        do {
            container = try ModelContainer(for: DownloadHistoryItem.self)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
        self.modelContainer = container
        
        // Initialize services
        let config = ConfigurationService()
        let githubAPI = GitHubAPIClient()
        let updater = BinaryUpdater(githubAPI: githubAPI)
        
        self.configService = config
        self.binaryUpdater = updater
        
        // Initialize business logic
        // Use FileSystemManager to get the correct binary path in Application Support
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let binaryPath = appSupportDir.appendingPathComponent("YTMac").appendingPathComponent("yt-dlp")
        let processExecutor = ProcessExecutor(binaryPath: binaryPath)
        let qualityGate = FreeQualityGate(configService: config)
        let historyStore = DownloadHistoryStore(modelContext: container.mainContext)
        
        let manager = DownloadManager(
            processExecutor: processExecutor,
            qualityGate: qualityGate,
            historyStore: historyStore,
            configService: config
        )
        self.downloadManager = manager
        
        // Initialize ViewModels
        _downloadViewModel = StateObject(wrappedValue: DownloadViewModel(downloadManager: manager))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(historyStore: historyStore, downloadManager: manager))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(configService: config, binaryUpdater: updater))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                downloadViewModel: downloadViewModel,
                historyViewModel: historyViewModel,
                settingsViewModel: settingsViewModel
            )
            .modelContainer(modelContainer)
            .onAppear {
                // Wire up dependencies for lifecycle management
                appDelegate.binaryUpdater = binaryUpdater
                appDelegate.downloadManager = downloadManager
            }
            .onReceive(appDelegate.$binaryError) { error in
                // Show alert when binary verification fails
                // Validates Requirement 3.1, 3.2: graceful error handling
                showBinaryErrorAlert = (error != nil)
            }
            .alert(
                "yt-dlp Binary Not Available",
                isPresented: $showBinaryErrorAlert
            ) {
                Button("OK") {
                    showBinaryErrorAlert = false
                }
            } message: {
                Text(appDelegate.binaryError ?? "Failed to verify yt-dlp binary. Downloads may not work until the binary is available.")
            }
        }
        .commands {
            AppCommands()
        }
    }
}
