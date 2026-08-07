//
//  DownloadRowView.swift
//  YTMac
//
//  A card-style row view displaying a download job with thumbnail, metadata,
//  progress bar, and status information.
//  Implements Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4,
//  8.1, 8.2, 8.3, 8.4, 8.5, 11.1, 11.2, 13.2, 13.3
//

import SwiftUI
import AppKit

/// Displays a single download job as a rich card with thumbnail, metadata, and progress.
///
/// Layout matches the TubeGrab Pro style:
/// - Leading thumbnail with duration overlay
/// - Title, channel info, quality/format badges, file size
/// - Full-width gradient progress bar
/// - Status row with percentage, speed, ETA, and downloaded/total
struct DownloadRowView: View {

    // MARK: - Properties

    let download: DownloadJobViewModel
    let onCancel: () -> Void

    @State private var showCompletionAnimation = false
    @State private var shimmerPhase: CGFloat = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top section: thumbnail + metadata + action buttons
            HStack(alignment: .top, spacing: 12) {
                thumbnailView
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title (bold primary text)
                    Text(download.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    // URL (always shown as secondary text below title when title is available)
                    if !download.title.isEmpty {
                        Text(download.url)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    // Channel info
                    if let channel = download.channelName {
                        Text(channel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Quality, format, and file size badges
                    HStack(spacing: 6) {
                        qualityBadge
                        formatBadge
                        
                        if let fileSize = download.fileSize {
                            Text(formattedBytes(fileSize))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                if canCancel {
                    // Cancel button for active/queued
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel download")
                } else if case .completed(let path) = download.status {
                    // Play and Reveal buttons for completed downloads
                    HStack(spacing: 6) {
                        Button {
                            NSWorkspace.shared.open(path)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play video")
                        .accessibilityHint("Opens the downloaded file with the default player")
                        
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([path])
                        } label: {
                            Image(systemName: "folder")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reveal in Finder")
                        .accessibilityHint("Opens Finder and selects the downloaded file")
                    }
                }
            }
            
            // Progress bar (full width)
            progressBarView
            
            // Status row
            statusRow
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cardBorderColor, lineWidth: isActive ? 1.5 : 1)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let thumbnailURL = download.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        thumbnailPlaceholder
                            .overlay(ProgressView().controlSize(.small))
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
            
            // Duration overlay
            if let duration = download.duration {
                Text(formattedDuration(duration))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(3)
                    .padding(4)
            }
        }
        .frame(width: 120, height: 68)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 68)
            .overlay(
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.5))
            )
    }

    // MARK: - Badges

    private var qualityBadge: some View {
        Text(download.quality.displayName.components(separatedBy: " ").first ?? "720p")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Color.blue.opacity(0.15))
            )
    }

    private var formatBadge: some View {
        Text(download.format.displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(Color.secondary.opacity(0.15))
            )
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBarView: some View {
        switch download.status {
        case .active(let progress):
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 4)

                    if download.isIndeterminate {
                        // Preparing: animated gradient sliding bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.4), .blue, .cyan, .blue, .blue.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.35, height: 4)
                            .offset(x: shimmerPhase * (geometry.size.width * 0.65))
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    shimmerPhase = 1.0
                                }
                            }
                    } else {
                        // Active: gradient fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DesignConstants.progressGradient)
                            .frame(width: max(4, geometry.size.width * progress.percentage), height: 4)
                            .animation(.spring(duration: 0.3), value: progress.percentage)
                    }
                }
            }
            .frame(height: 4)
        case .completed:
            // No progress bar for completed — just the status text below
            EmptyView()
        default:
            EmptyView()
        }
    }

    // MARK: - Status Row

    @ViewBuilder
    private var statusRow: some View {
        switch download.status {
        case .active(let progress):
            if download.isIndeterminate {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Preparing download…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 0) {
                    statusDot(color: .green)
                    Text("Downloading")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    divider
                    
                    Text("\(Int(progress.percentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    
                    divider
                    
                    Text(formattedSpeed(progress.speed))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    divider
                    
                    Text(formattedETA(progress.eta))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    divider
                    
                    Text("\(formattedBytes(progress.downloadedBytes)) / \(formattedBytes(progress.totalBytes))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        case .queued:
            HStack(spacing: 8) {
                statusDot(color: .orange)
                Text("Queued")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        case .completed:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                    .scaleEffect(showCompletionAnimation ? 1.0 : 0.5)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: showCompletionAnimation)
                    .onAppear { showCompletionAnimation = true }
                Text("Download complete")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        case .failed(let error):
            HStack(spacing: 8) {
                statusDot(color: .orange)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        case .cancelled:
            HStack(spacing: 8) {
                statusDot(color: .gray)
                Text("Cancelled")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Helpers

    private func statusDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }

    private var divider: some View {
        Text("  |  ")
            .font(.caption)
            .foregroundColor(.secondary.opacity(0.5))
    }

    private var canCancel: Bool {
        switch download.status {
        case .queued, .active: return true
        default: return false
        }
    }

    private var isActive: Bool {
        if case .active = download.status { return true }
        return false
    }

    private var cardBorderColor: Color {
        switch download.status {
        case .active:
            return .accentColor
        case .completed:
            return .green.opacity(0.4)
        case .failed:
            return .orange.opacity(0.4)
        default:
            return .primary.opacity(0.12)
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formattedSpeed(_ bytesPerSecond: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return "\(formatter.string(fromByteCount: bytesPerSecond))/s"
    }

    private func formattedETA(_ seconds: TimeInterval) -> String {
        if seconds <= 0 { return "ETA --:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "ETA \(String(format: "%d:%02d", mins, secs))"
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview

#Preview("Active Download") {
    DownloadRowView(
        download: DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=abc123",
            title: "Rick Astley - Never Gonna Give You Up (Official Music Video)",
            quality: .standard720p,
            status: .active(progress: DownloadProgress(
                percentage: 0.67,
                downloadedBytes: 32_300_000,
                totalBytes: 48_200_000,
                speed: 3_200_000,
                eta: 8
            )),
            progress: DownloadProgress(
                percentage: 0.67,
                downloadedBytes: 32_300_000,
                totalBytes: 48_200_000,
                speed: 3_200_000,
                eta: 8
            ),
            createdAt: Date(),
            completedAt: nil,
            outputPath: nil,
            errorMessage: nil,
            thumbnailURL: URL(string: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"),
            channelName: "Rick Astley",
            duration: 213,
            fileSize: 48_200_000
        )),
        onCancel: {}
    )
    .frame(width: 600)
    .padding()
}

#Preview("Indeterminate") {
    DownloadRowView(
        download: DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=abc123",
            title: "",
            quality: .standard720p,
            status: .active(progress: DownloadProgress(
                percentage: 0,
                downloadedBytes: 0,
                totalBytes: 0,
                speed: 0,
                eta: 0
            )),
            progress: DownloadProgress(
                percentage: 0,
                downloadedBytes: 0,
                totalBytes: 0,
                speed: 0,
                eta: 0
            ),
            createdAt: Date()
        )),
        onCancel: {}
    )
    .frame(width: 600)
    .padding()
}

#Preview("Queued") {
    DownloadRowView(
        download: DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=def456",
            title: "Me at the zoo",
            quality: .standard720p,
            status: .queued,
            channelName: "jawed",
            duration: 19,
            fileSize: 4_100_000
        )),
        onCancel: {}
    )
    .frame(width: 600)
    .padding()
}

#Preview("Failed") {
    DownloadRowView(
        download: DownloadJobViewModel(from: DownloadJob(
            id: UUID(),
            url: "https://www.youtube.com/watch?v=invalid",
            title: "Unavailable Video",
            quality: .standard720p,
            status: .failed(error: "This video is unavailable"),
            createdAt: Date(),
            errorMessage: "This video is unavailable"
        )),
        onCancel: {}
    )
    .frame(width: 600)
    .padding()
}
