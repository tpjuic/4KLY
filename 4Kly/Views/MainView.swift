//
//  MainView.swift
//  YTMac
//
//  Main download interface view - the primary screen users interact with.
//  Implements Requirements: 1.1, 2.2, 4.4, 5.5, 7.1, 7.3, 7.4, 7.5
//

import SwiftUI
import SwiftData

/// The primary download interface view.
///
/// Presents the URL input, quality picker, download button, and active/queued downloads
/// list. Handles upgrade prompts when premium quality is selected, and displays
/// error messages for validation or download failures.
struct MainView: View {
    
    // MARK: - Properties
    
    /// The download view model managing download state and actions
    @ObservedObject var viewModel: DownloadViewModel
    
    /// Tracks whether a download submission is in progress
    @State private var isSubmitting: Bool = false
    
    /// Controls focus on the URL input field (triggered by ⌘N "New Download" menu command)
    @Binding var focusURLInput: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Banner (positioned above input section)
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .padding(.bottom, -8)
            }
            
            // URL Input Section
            inputSection
            
            Divider()
            
            // Downloads List Section
            DownloadListView(
                activeDownloads: viewModel.activeDownloads,
                queuedDownloads: viewModel.queuedDownloads,
                completedDownloads: viewModel.completedDownloads,
                onCancel: { id in
                    Task {
                        await viewModel.cancelDownload(id: id)
                    }
                }
            )
        }
        .animation(.spring(duration: DesignConstants.animationDuration), value: viewModel.errorMessage)
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            UpgradePromptSheet(
                promptInfo: viewModel.upgradePromptInfo,
                onUpgrade: {
                    viewModel.openUpgradeURL()
                    viewModel.showUpgradePrompt = false
                },
                onDismiss: {
                    viewModel.showUpgradePrompt = false
                }
            )
        }
    }
    
    // MARK: - Input Section
    
    /// Top section containing URL input, quality picker, and download button
    private var inputSection: some View {
        VStack(spacing: 12) {
            // URL text input
            URLInputView(urlInput: $viewModel.urlInput, shouldFocus: $focusURLInput)
            
            // Quality picker, format picker, and download button row
            HStack(spacing: 12) {
                QualityPickerView(selectedQuality: $viewModel.selectedQuality)
                    .disabled(viewModel.selectedFormat.isAudioOnly)
                    .opacity(viewModel.selectedFormat.isAudioOnly ? 0.5 : 1.0)
                    .frame(maxWidth: 220)
                
                FormatPickerView(selectedFormat: $viewModel.selectedFormat)
                
                Spacer()
                
                // Download button
                Button(action: {
                    isSubmitting = true
                    Task {
                        await viewModel.submitDownload()
                        isSubmitting = false
                    }
                }) {
                    HStack(spacing: 6) {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text("Download")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("Download video")
                .accessibilityHint("Downloads the video at the specified URL with the selected quality")
            }
        }
    }
    
}

// MARK: - Preview

#Preview("Main View") {
    // Preview requires a DownloadViewModel - use a simplified version for previewing
    struct PreviewWrapper: View {
        @StateObject private var viewModel: DownloadViewModel = {
            // Create minimal dependencies for preview
            let configService = ConfigurationService()
            let processExecutor = ProcessExecutor(binaryPath: URL(fileURLWithPath: "/usr/local/bin/yt-dlp"))
            let qualityGate = FreeQualityGate(configService: configService)
            
            // Create a DownloadManager with a placeholder history store
            // Note: In preview, the history store won't be functional
            let container = try! ModelContainer(for: DownloadHistoryItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let historyStore = DownloadHistoryStore(modelContext: container.mainContext)
            
            let manager = DownloadManager(
                processExecutor: processExecutor,
                qualityGate: qualityGate,
                historyStore: historyStore,
                configService: configService
            )
            return DownloadViewModel(downloadManager: manager)
        }()
        
        @State private var focusURL = false
        
        var body: some View {
            MainView(viewModel: viewModel, focusURLInput: $focusURL)
        }
    }
    
    return PreviewWrapper()
}
