//
//  HistoryCardView.swift
//  YTMac
//
//  A card-styled history row with thumbnail placeholder, quality badge,
//  relative date, and contextual action buttons.
//  Implements Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 12.4
//

import SwiftUI

/// A card-style view displaying a single download history item.
///
/// Shows a thumbnail placeholder, video title, quality badge, relative date,
/// and contextual actions depending on whether the download completed or failed.
struct HistoryCardView: View {

    // MARK: - Properties

    /// The download history item to display
    let item: DownloadHistoryItem

    /// Callback invoked when the user taps the retry/re-download button
    let onRedownload: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DesignConstants.baseSpacing) {
            thumbnailView

            VStack(alignment: .leading, spacing: DesignConstants.relatedSpacing) {
                // Title
                Text(item.title.isEmpty ? item.url : item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.tail)

                // URL below title (only if title is available)
                if !item.title.isEmpty && item.title != "Unknown Title" {
                    Text(item.url)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // Quality badge, format badge, and relative date
                HStack(spacing: DesignConstants.relatedSpacing) {
                    qualityBadge
                    formatBadge
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Status-specific content
                if isCompleted {
                    completedActions
                } else {
                    failedActions
                }
            }

            Spacer(minLength: 0)
        }
        .padding(DesignConstants.baseSpacing)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Thumbnail

    /// Shows real YouTube thumbnail or placeholder
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = youTubeThumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadius / 2))
                case .failure:
                    thumbnailPlaceholder
                case .empty:
                    thumbnailPlaceholder
                @unknown default:
                    thumbnailPlaceholder
                }
            }
            .frame(width: 80, height: 56)
        } else {
            thumbnailPlaceholder
        }
    }

    // MARK: - Thumbnail Placeholder

    /// Gray rounded rectangle with a play icon overlay (60x45)
    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius / 2)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 45)

            Image(systemName: "play.fill")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.6))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Quality Badge

    /// Styled pill/capsule displaying the quality (e.g., "720p")
    private var qualityBadge: some View {
        Text(qualityLabel)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.12))
            )
            .foregroundColor(.blue)
    }

    // MARK: - Format Badge

    /// Styled pill/capsule displaying the format (e.g., "MP4", "MP3")
    private var formatBadge: some View {
        Text(item.resolvedFormat)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
            )
            .foregroundColor(.secondary)
    }

    // MARK: - Completed Actions

    /// File size, play button, and reveal in Finder for completed downloads
    private var completedActions: some View {
        HStack(spacing: DesignConstants.relatedSpacing) {
            if let outputPath = item.outputPath {
                // File size
                Text(formattedFileSize(path: outputPath))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Play button
                Button {
                    openFile(path: outputPath)
                } label: {
                    Label("Play", systemImage: "play.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Play video")
                .accessibilityHint("Opens the video file with the default player")

                // Reveal in Finder
                Button {
                    revealInFinder(path: outputPath)
                } label: {
                    Label("Reveal", systemImage: "folder")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Reveal in Finder")
                .accessibilityHint("Opens Finder and selects the downloaded file")
            }
        }
    }

    // MARK: - Failed Actions

    /// Prominent retry button for failed downloads
    private var failedActions: some View {
        VStack(alignment: .leading, spacing: DesignConstants.relatedSpacing) {
            if let errorMessage = item.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Button {
                onRedownload()
            } label: {
                Label("Retry Download", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.small)
            .accessibilityLabel("Retry download")
            .accessibilityHint("Attempts to download this video again")
        }
    }

    // MARK: - Helpers

    /// Whether the history item represents a completed download
    private var isCompleted: Bool {
        item.status == "completed"
    }

    /// Extracts YouTube thumbnail URL from the video URL
    private var youTubeThumbnailURL: URL? {
        guard let components = URLComponents(string: item.url) else { return nil }
        var videoID: String?
        
        if let host = components.host?.lowercased() {
            if host.contains("youtube.com") || host.contains("youtube-nocookie.com") {
                if components.path.hasPrefix("/shorts/") {
                    videoID = String(components.path.dropFirst("/shorts/".count)).components(separatedBy: "/").first
                } else {
                    videoID = components.queryItems?.first(where: { $0.name == "v" })?.value
                }
            } else if host.contains("youtu.be") {
                videoID = String(components.path.dropFirst())
            }
        }
        
        guard let id = videoID, !id.isEmpty else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
    }

    /// Extracts just the resolution part from the quality string (e.g., "720p" from "720p (Standard)")
    private var qualityLabel: String {
        let quality = item.quality
        if let parenRange = quality.range(of: " (") {
            return String(quality[quality.startIndex..<parenRange.lowerBound])
        }
        return quality
    }

    /// Relative date string using RelativeDateTimeFormatter
    private var relativeDate: String {
        let displayDate = item.completedAt ?? item.createdAt
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: displayDate, relativeTo: Date())
    }

    /// Formats file size using ByteCountFormatter
    private func formattedFileSize(path: String) -> String {
        let fileURL = URL(fileURLWithPath: path)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attrs[.size] as? Int64 else {
            return ""
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Opens the file with the default system application
    private func openFile(path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(fileURL)
    }

    /// Opens Finder with the specified file selected
    private func revealInFinder(path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    /// Accessibility description for the entire card
    private var accessibilityDescription: String {
        let status = isCompleted ? "Completed" : "Failed"
        let title = item.title.isEmpty ? item.url : item.title
        return "\(title), \(qualityLabel), \(status), \(relativeDate)"
    }
}

// MARK: - Previews

#Preview("Completed Download") {
    HistoryCardView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=abc123",
            title: "SwiftUI Tutorial - Building a macOS App from Scratch",
            quality: "720p (Standard)",
            outputPath: "/Users/test/Downloads/SwiftUI Tutorial.mp4",
            status: "completed",
            createdAt: Date().addingTimeInterval(-3600),
            completedAt: Date().addingTimeInterval(-1800)
        ),
        onRedownload: {}
    )
    .frame(width: 500)
    .padding()
}

#Preview("Failed Download") {
    HistoryCardView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=invalid",
            title: "Unavailable Video - This Title Is Quite Long",
            quality: "480p (Standard)",
            status: "failed",
            errorMessage: "This video is unavailable. Please check the URL and try again.",
            createdAt: Date().addingTimeInterval(-7200)
        ),
        onRedownload: {}
    )
    .frame(width: 500)
    .padding()
}

#Preview("Completed Without File Path") {
    HistoryCardView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=def456",
            title: "Learn Swift Concurrency",
            quality: "360p",
            status: "completed",
            createdAt: Date().addingTimeInterval(-86400),
            completedAt: Date().addingTimeInterval(-86000)
        ),
        onRedownload: {}
    )
    .frame(width: 500)
    .padding()
}

#Preview("Dark Mode - Completed") {
    HistoryCardView(
        item: DownloadHistoryItem(
            url: "https://www.youtube.com/watch?v=abc123",
            title: "Dark Mode Testing Video",
            quality: "1080p (Premium)",
            outputPath: "/Users/test/Downloads/Dark Mode Test.mp4",
            status: "completed",
            createdAt: Date().addingTimeInterval(-600),
            completedAt: Date()
        ),
        onRedownload: {}
    )
    .frame(width: 500)
    .padding()
    .preferredColorScheme(.dark)
}
