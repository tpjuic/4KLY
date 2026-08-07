//
//  BrandedTitleView.swift
//  YTMac
//
//  Shared design constants and branded title component.
//  Implements Requirements: 1.1, 1.2, 1.3, 1.4, 12.1, 12.2, 12.3, 12.4
//

import SwiftUI

// MARK: - Design Constants

/// Shared design constants for consistent spacing, sizing, and styling across the app.
enum DesignConstants {
    static let baseSpacing: CGFloat = 16
    static let relatedSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 8
    static let emptyStateIconSize: CGFloat = 48
    static let animationDuration: Double = 0.3
    static let completionAnimationDuration: Double = 0.6
    static let errorBannerAutoDismiss: TimeInterval = 8

    static let progressGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let premiumGradient = LinearGradient(
        colors: [Color.purple, Color.blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - BrandedTitleView

/// A reusable view that renders "YT" in bold and "Mac" in regular weight.
///
/// Use this view in the sidebar header and toolbar to provide consistent
/// branded typography throughout the app.
struct BrandedTitleView: View {
    var size: Font.TextStyle = .headline

    var body: some View {
        (Text("YT").bold() + Text("Mac"))
            .font(.system(size: fontSize, weight: .regular))
    }

    /// Maps a `Font.TextStyle` to an appropriate point size following
    /// the app's typography hierarchy.
    private var fontSize: CGFloat {
        switch size {
        case .largeTitle:
            return 26
        case .title:
            return 22
        case .title2:
            return 20
        case .title3:
            return 18
        case .headline:
            return 15
        case .body:
            return 13
        case .callout:
            return 12
        case .subheadline:
            return 11
        case .footnote:
            return 10
        case .caption:
            return 11
        case .caption2:
            return 10
        @unknown default:
            return 15
        }
    }
}

// MARK: - Previews

#Preview("Headline (default)") {
    BrandedTitleView()
        .padding()
}

#Preview("Title") {
    BrandedTitleView(size: .title)
        .padding()
}

#Preview("Large Title") {
    BrandedTitleView(size: .largeTitle)
        .padding()
}

#Preview("Light and Dark") {
    VStack(spacing: 20) {
        BrandedTitleView(size: .title)
            .environment(\.colorScheme, .light)
        BrandedTitleView(size: .title)
            .environment(\.colorScheme, .dark)
    }
    .padding()
}
