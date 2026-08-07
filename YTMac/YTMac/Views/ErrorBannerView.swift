//
//  ErrorBannerView.swift
//  YTMac
//
//  A dismissible error banner with auto-dismiss timer.
//  Implements Requirements: 11.2, 11.3, 11.4
//

import SwiftUI

/// A banner-style error notification that appears at the top of the content area.
///
/// Displays an orange warning icon with an error message and a manual dismiss button.
/// Automatically dismisses after 8 seconds. Uses spring animation for appearance.
struct ErrorBannerView: View {

    // MARK: - Properties

    /// The error message to display
    let message: String

    /// Callback invoked when the banner is dismissed (manually or via timer)
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignConstants.relatedSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.body)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.6))
                    .font(.body)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(DesignConstants.relatedSpacing + 4)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(DesignConstants.errorBannerAutoDismiss))
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Previews

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(
            message: "yt-dlp binary not found. Please check your installation.",
            onDismiss: {}
        )
        .padding()

        Spacer()
    }
    .frame(width: 500, height: 300)
}

#Preview("Error Banner - Long Message") {
    VStack {
        ErrorBannerView(
            message: "Network connection lost. Downloads will resume automatically when connectivity is restored.",
            onDismiss: {}
        )
        .padding()

        Spacer()
    }
    .frame(width: 500, height: 300)
}

#Preview("Error Banner - Dark Mode") {
    VStack {
        ErrorBannerView(
            message: "Failed to access download folder. Please re-select a folder in Settings.",
            onDismiss: {}
        )
        .padding()

        Spacer()
    }
    .frame(width: 500, height: 300)
    .preferredColorScheme(.dark)
}
