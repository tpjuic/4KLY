//
//  SettingsView.swift
//  YTMac
//
//  Settings view for configuring app preferences
//  Implements Requirements: 8.1, 8.2, 13.2, 13.3, 7.1, 7.4, 7.5
//

import SwiftUI

/// Settings view displaying download location, yt-dlp version/update controls, and about information
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            // MARK: - Downloads Section
            // Requirement 8.1, 8.2: Settings panel for download location configuration
            Section("Downloads") {
                HStack {
                    Text("Save to:")
                    Spacer()
                    Text(viewModel.downloadLocation.lastPathComponent)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Change...") {
                        Task { await viewModel.selectDownloadLocation() }
                    }
                }
            }
            
            // MARK: - Download Engine Section
            // Requirement 13.2, 13.3: Download engine version display and update controls
            Section("Download Engine") {
                HStack {
                    Text("Version:")
                    Spacer()
                    if viewModel.isCheckingForUpdates {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(viewModel.currentYtdlpVersion)
                        .foregroundColor(.secondary)
                    
                    if viewModel.availableYtdlpUpdate == nil && !viewModel.isCheckingForUpdates && viewModel.currentYtdlpVersion != "Checking..." && viewModel.currentYtdlpVersion != "Error" && viewModel.currentYtdlpVersion != "Unknown" {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if viewModel.availableYtdlpUpdate == nil && !viewModel.isCheckingForUpdates {
                    HStack {
                        Text("Up to date")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
                
                Button("Check for Updates") {
                    Task { await viewModel.checkForYtdlpUpdates() }
                }
                .disabled(viewModel.isCheckingForUpdates || viewModel.isUpdatingYtdlp)
                
                if let update = viewModel.availableYtdlpUpdate {
                    HStack {
                        Text("Update available: \(update.latestVersion)")
                            .foregroundColor(.green)
                        Spacer()
                        if viewModel.isUpdatingYtdlp {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("Install Update") {
                                Task { await viewModel.installYtdlpUpdate() }
                            }
                        }
                    }
                }
            }
            
            // MARK: - About Section
            // Requirement 7.1, 7.4, 7.5: Native macOS UI with app information
            Section("About") {
                HStack {
                    Text("YTMac Version:")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                Link("Visit Website",
                     destination: URL(string: "https://ytmac.app")!)
                
                Text("Powered by yt-dlp")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YTMac is free and open source")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("Support development with Premium →",
                         destination: URL(string: "https://ytmac.app/premium")!)
                        .font(.caption)
                }
            }
            
            // MARK: - Error Message
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Private Helpers
    
    /// App version from Bundle.main
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            configService: ConfigurationService(),
            binaryUpdater: BinaryUpdater(
                githubAPI: GitHubAPIClient()
            )
        )
    )
}
