//
//  DownloadListView.swift
//  YTMac
//
//  List view displaying downloads with filter tabs (All, Downloading, Queued, Completed)
//  Implements Requirements: 5.5, 5.6, 7.4
//

import SwiftUI

/// Filter tabs for the download list
enum DownloadFilter: String, CaseIterable {
    case all = "All"
    case downloading = "Downloading"
    case queued = "Queued"
    case completed = "Completed"
}

/// A list view that displays all downloads with filter tabs.
///
/// Shows downloads organized by status with filter tabs at the top.
/// Completed/failed downloads stay visible in this view (not just in History).
struct DownloadListView: View {
    
    // MARK: - Properties
    
    let activeDownloads: [DownloadJobViewModel]
    let queuedDownloads: [DownloadJobViewModel]
    let completedDownloads: [DownloadJobViewModel]
    let onCancel: (UUID) -> Void
    
    @State private var selectedFilter: DownloadFilter = .all
    
    // MARK: - Computed Properties
    
    private var allDownloads: [DownloadJobViewModel] {
        activeDownloads + queuedDownloads + completedDownloads
    }
    
    private var filteredDownloads: [DownloadJobViewModel] {
        switch selectedFilter {
        case .all:
            return allDownloads
        case .downloading:
            return activeDownloads
        case .queued:
            return queuedDownloads
        case .completed:
            return completedDownloads
        }
    }
    
    private var isEmpty: Bool {
        allDownloads.isEmpty
    }
    
    private var itemCount: Int {
        allDownloads.count
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with count and filter tabs
            if !isEmpty {
                headerView
                    .padding(.bottom, 8)
            }
            
            // Content
            if isEmpty {
                emptyStateView
            } else if filteredDownloads.isEmpty {
                filteredEmptyView
            } else {
                downloadList
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Item count
            Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.secondary.opacity(0.12)))
            
            Spacer()
            
            // Filter tabs
            HStack(spacing: 2) {
                ForEach(DownloadFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundColor(selectedFilter == filter ? .primary : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                selectedFilter == filter
                                    ? Color.primary.opacity(0.08)
                                    : Color.clear
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: DesignConstants.emptyStateIconSize))
                .foregroundColor(.secondary)
            
            Text("No downloads in progress")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Paste a video URL above to start downloading")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No downloads in progress")
    }
    
    private var filteredEmptyView: some View {
        VStack(spacing: 8) {
            Text("No \(selectedFilter.rawValue.lowercased()) downloads")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Download List
    
    private var downloadList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredDownloads) { download in
                    DownloadRowView(
                        download: download,
                        onCancel: { onCancel(download.id) }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .animation(.spring(duration: DesignConstants.animationDuration), value: filteredDownloads.count)
        .accessibilityLabel("Downloads list")
    }
}

// MARK: - Preview

#Preview("Empty State") {
    DownloadListView(
        activeDownloads: [],
        queuedDownloads: [],
        completedDownloads: [],
        onCancel: { _ in }
    )
    .frame(width: 600, height: 400)
}

#Preview("With Downloads") {
    let activeJobs = [
        DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=abc123",
            title: "Sample Video 1",
            quality: .standard720p,
            status: .active(progress: DownloadProgress(
                percentage: 0.45,
                downloadedBytes: 23_000_000,
                totalBytes: 51_000_000,
                speed: 2_500_000,
                eta: 12
            )),
            progress: DownloadProgress(
                percentage: 0.45,
                downloadedBytes: 23_000_000,
                totalBytes: 51_000_000,
                speed: 2_500_000,
                eta: 12
            ),
            createdAt: Date(),
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"),
            channelName: "Test Channel",
            duration: 213,
            fileSize: 51_000_000
        ))
    ]
    
    let queuedJobs = [
        DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=def456",
            title: "Sample Video 2",
            quality: .standard480p,
            status: .queued,
            channelName: "Another Channel",
            duration: 300
        ))
    ]
    
    let completedJobs = [
        DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=ghi789",
            title: "Completed Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/video.mp4")),
            channelName: "Done Channel",
            duration: 180,
            fileSize: 45_000_000
        ))
    ]
    
    DownloadListView(
        activeDownloads: activeJobs,
        queuedDownloads: queuedJobs,
        completedDownloads: completedJobs,
        onCancel: { _ in }
    )
    .frame(width: 600, height: 500)
}
