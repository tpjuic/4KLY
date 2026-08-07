//
//  HistoryRowView.swift
//  YTMac
//
//  A row view displaying a single download history item with status, details, and actions.
//  Implements Requirements: 6.3, 6.6, 7.4
//

import SwiftUI

/// Displays a single download history item in the history list.
///
/// Shows title, URL (truncated), quality, and formatted date for all items.
/// For completed downloads, shows the output path with a "Reveal in Finder" button.
/// For failed downloads, shows the error message in red.
/// Includes a "Re-download" button for all items.
struct HistoryRowView: View {
    
    // MARK: - Properties
    
    /// The download history item to display
    let item: DownloadHistoryItem
    
    /// Callback invoked when the user taps the "Re-download" button
    let onRedownload: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                // URL and quality
                HStack(spacing: 8) {
                    Text(truncatedURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.quality)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Formatted date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Status-specific detail
                statusDetailView
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                if isCompleted, let outputPath = item.outputPath {
                    Button {
                        revealInFinder(path: outputPath)
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Reveal in Finder")
                    .accessibilityHint("Opens Finder and selects the downloaded file")
                }
                
                Button {
                    onRedownload()
                } label: {
                    Label("Re-download", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Re-download")
                .accessibilityHint("Downloads this video again with the same settings")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Status Icon
    
    /// SF Symbol icon representing the download result status
    @ViewBuilder
    private var statusIcon: some View {
        if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .accessibilityLabel("Completed")
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
                .accessibilityLabel("Failed")
        }
    }
    
    // MARK: - Status Detail View
    
    /// Shows output path for completed downloads or error message for failed ones
    @ViewBuilder
    private var statusDetailView: some View {
        if isCompleted {
            if let outputPath = item.outputPath {
                Text(outputPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(outputPath)
            }
        } else if let errorMessage = item.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(2)
        }
    }
    
    // MARK: - Helpers
    
    /// Whether the history item represents a completed download
    private var isCompleted: Bool {
        item.status == "completed"
    }
    
    /// Truncated URL for display (shows domain and path start)
    private var truncatedURL: String {
        if item.url.count > 60 {
            return String(item.url.prefix(57)) + "…"
        }
        return item.url
    }
    
    /// Formatted date string using relative date formatting
    private var formattedDate: String {
        let displayDate = item.completedAt ?? item.createdAt
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: displayDate, relativeTo: Date())
    }
    
    /// Opens Finder with the specified file selected
    private func revealInFinder(path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    /// Accessibility description for the entire row
    private var accessibilityDescription: String {
        let status = isCompleted ? "Completed" : "Failed"
        return "\(item.title), \(item.quality), \(status), \(formattedDate)"
    }
}

// MARK: - Preview

#Preview("Completed History Item") {
    HistoryRowView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=abc123",
            title: "SwiftUI Tutorial - Building a macOS App",
            quality: "720p (Standard)",
            outputPath: "/Users/test/Downloads/SwiftUI Tutorial.mp4",
            status: "completed",
            createdAt: Date().addingTimeInterval(-3600),
            completedAt: Date()
        ),
        onRedownload: {}
    )
    .frame(width: 600)
    .padding()
}

#Preview("Failed History Item") {
    HistoryRowView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=invalid",
            title: "Unavailable Video - This Title Is Very Long And Should Be Truncated",
            quality: "480p (Standard)",
            status: "failed",
            errorMessage: "This video is unavailable. Please check the URL and try again.",
            createdAt: Date().addingTimeInterval(-7200)
        ),
        onRedownload: {}
    )
    .frame(width: 600)
    .padding()
}

#Preview("Completed Without Path") {
    HistoryRowView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=def456&list=PLsomething&index=5",
            title: "Learn Swift Concurrency",
            quality: "360p (Standard)",
            status: "completed",
            createdAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-86000)
        ),
        onRedownload: {}
    )
    .frame(width: 600)
    .padding()
}
