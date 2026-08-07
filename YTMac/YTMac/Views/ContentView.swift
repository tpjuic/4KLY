//
//  ContentView.swift
//  YTMac
//
//  Main application content view with NavigationSplitView
//  Implements Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1, 9.3, 9.4, 9.5
//

import SwiftUI
import SwiftData

// MARK: - ContentView

/// The root content view providing NavigationSplitView with sidebar and detail.
///
/// Displays a sidebar with navigation links to Downloads, History, and Settings,
/// and renders the corresponding view in the detail area based on selection.
/// Sets a minimum window size of 800x600 per macOS HIG recommendations.
struct ContentView: View {
    
    // MARK: - Properties
    
    /// The currently selected navigation section
    @State private var selectedSection: NavigationSection? = .downloads
    
    /// Triggers the "New Download" action from the menu bar (⌘N)
    @State private var newDownloadAction: Bool = false
    
    /// Controls onboarding sheet presentation on first launch
    @State private var showOnboarding = false
    
    /// ViewModel for the Downloads view
    @ObservedObject var downloadViewModel: DownloadViewModel
    
    /// ViewModel for the History view
    @ObservedObject var historyViewModel: HistoryViewModel
    
    /// ViewModel for the Settings view
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            selectedSection = .settings
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Settings")
                        .help("Open Settings")
                    }
                }
        }
        .frame(minWidth: 800, minHeight: 600)
        .focusedSceneValue(\.selectedSection, $selectedSection)
        .focusedSceneValue(\.newDownloadAction, $newDownloadAction)
        .onChange(of: newDownloadAction) { _, newValue in
            if newValue {
                // Navigate to Downloads tab — the focus trigger propagates
                // through the binding to URLInputView
                selectedSection = .downloads
            }
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedOnboarding.rawValue) {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingPermissionView(
                isPresented: $showOnboarding,
                downloadFolderPath: settingsViewModel.downloadLocation.path,
                onGrantAccess: {
                    presentFolderSelectionPanel()
                    UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedOnboarding.rawValue)
                },
                onSkip: {
                    UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedOnboarding.rawValue)
                }
            )
        }
    }
    
    // MARK: - Sidebar
    
    /// Sidebar listing navigation sections with SF Symbol icons and branded header
    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section("LIBRARY") {
                ForEach(NavigationSection.allCases.filter { $0.group == .library }) { section in
                    sidebarRow(for: section)
                        .tag(section)
                }
            }
            
            Section("COLLECTIONS") {
                ForEach(NavigationSection.allCases.filter { $0.group == .collections }) { section in
                    sidebarRow(for: section)
                        .tag(section)
                }
            }
            
            Section("SYSTEM") {
                ForEach(NavigationSection.allCases.filter { $0.group == .system }) { section in
                    sidebarRow(for: section)
                        .tag(section)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                BrandedTitleView(size: .title)
                Text("v\(appVersion)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
        .listStyle(.sidebar)
    }
    
    /// Footer at the bottom of the sidebar with version info
    private var sidebarFooter: some View {
        VStack(spacing: 4) {
            Divider()
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Connected")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("v\(appVersion)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    /// App version from bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Builds a sidebar row, applying a badge to the Downloads item when active downloads exist.
    @ViewBuilder
    private func sidebarRow(for section: NavigationSection) -> some View {
        let label = Label(section.title, systemImage: section.icon)
        if section == .downloads, downloadViewModel.activeDownloadCount > 0 {
            label.badge(downloadViewModel.activeDownloadCount)
        } else {
            label
        }
    }
    
    // MARK: - Folder Selection
    
    /// Presents an NSOpenPanel for the user to choose a download folder.
    private func presentFolderSelectionPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose a folder for saving downloaded videos"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            // Persist the selected folder via UserDefaults (same storage as ConfigurationService)
            UserDefaults.standard.set(url.path, forKey: UserDefaultsKey.downloadLocation.rawValue)
            settingsViewModel.downloadLocation = url
        }
    }
    
    // MARK: - Detail View
    
    /// Detail area showing the view corresponding to the selected sidebar item
    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .downloads:
            MainView(viewModel: downloadViewModel, focusURLInput: $newDownloadAction)
                .navigationTitle("Downloads")
        case .history:
            HistoryView(viewModel: historyViewModel)
                .navigationTitle("History")
        case .music:
            HistoryView(viewModel: historyViewModel, formatFilter: "MP3")
                .navigationTitle("Music")
        case .videos:
            HistoryView(viewModel: historyViewModel, formatFilter: "MP4")
                .navigationTitle("Videos")
        case .settings:
            SettingsView(viewModel: settingsViewModel)
        case nil:
            Text("Select a section")
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    // Create minimal dependencies for preview
    let configService = ConfigurationService()
    let processExecutor = ProcessExecutor(binaryPath: URL(fileURLWithPath: "/usr/local/bin/yt-dlp"))
    let qualityGate = FreeQualityGate(configService: configService)
    
    let container = try! ModelContainer(
        for: DownloadHistoryItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let historyStore = DownloadHistoryStore(modelContext: container.mainContext)
    
    let downloadManager = DownloadManager(
        processExecutor: processExecutor,
        qualityGate: qualityGate,
        historyStore: historyStore,
        configService: configService
    )
    
    let downloadVM = DownloadViewModel(downloadManager: downloadManager)
    let historyVM = HistoryViewModel(historyStore: historyStore, downloadManager: downloadManager)
    let settingsVM = SettingsViewModel(configService: configService, binaryUpdater: BinaryUpdater(githubAPI: GitHubAPIClient()))
    
    ContentView(
        downloadViewModel: downloadVM,
        historyViewModel: historyVM,
        settingsViewModel: settingsVM
    )
    .modelContainer(container)
}
