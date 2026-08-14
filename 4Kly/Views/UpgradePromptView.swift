//
//  UpgradePromptView.swift
//  YTMac
//
//  Premium upgrade prompt sheet with feature comparison and gradient CTA.
//  Implements Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6
//

import SwiftUI

/// A standalone sheet view presenting the premium upgrade prompt.
///
/// Replaces the previous alert-based `UpgradePromptModifier` with a visually rich
/// sheet that includes a feature comparison, gradient call-to-action button, and
/// a secondary dismiss option. Designed for `.sheet` presentation from MainView.
struct UpgradePromptSheet: View {

    // MARK: - Properties

    /// The upgrade prompt information containing message and optional URL
    let promptInfo: UpgradePromptInfo?

    /// Action invoked when the user taps "Try Premium"
    let onUpgrade: () -> Void

    /// Action invoked when the user taps "Maybe Later"
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignConstants.baseSpacing * 1.25) {
            // Header icon
            headerIcon

            // Title
            Text("Unlock Premium Quality")
                .font(.title2.bold())

            // Feature comparison
            featureComparison

            // Message from promptInfo
            if let message = promptInfo?.message {
                Text(message)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, DesignConstants.baseSpacing)
            }
            
            Text("Your purchase supports independent development")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer(minLength: DesignConstants.relatedSpacing)

            // CTA buttons
            VStack(spacing: DesignConstants.relatedSpacing + 4) {
                // Try Premium button
                Button(action: onUpgrade) {
                    Text("Try Premium")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                                .fill(DesignConstants.premiumGradient)
                        )
                }
                .buttonStyle(.plain)
                .controlSize(.large)
                .accessibilityLabel("Try Premium")
                .accessibilityHint("Opens the premium upgrade page")

                // Maybe Later dismiss
                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Maybe Later")
                .accessibilityHint("Dismisses the upgrade prompt")
            }
            .padding(.bottom, DesignConstants.baseSpacing)
        }
        .padding(.horizontal, DesignConstants.baseSpacing * 1.5)
        .padding(.top, DesignConstants.baseSpacing * 1.5)
        .frame(width: 400, height: 380)
    }

    // MARK: - Subviews

    /// Crown/sparkles icon header
    private var headerIcon: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 40))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .accessibilityHidden(true)
    }

    /// Two-column feature comparison (Free vs Premium)
    private var featureComparison: some View {
        HStack(spacing: DesignConstants.baseSpacing) {
            // Free tier
            featureColumn(
                tier: "Free",
                quality: "Up to 720p",
                icon: "play.rectangle",
                color: .secondary
            )

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, DesignConstants.relatedSpacing)

            // Premium tier
            featureColumn(
                tier: "Premium",
                quality: "Up to 4K",
                icon: "sparkles",
                color: .purple
            )
        }
        .padding(DesignConstants.baseSpacing)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .fill(Color.primary.opacity(0.04))
        )
        .padding(.horizontal, DesignConstants.relatedSpacing)
    }

    /// A single tier column in the feature comparison
    private func featureColumn(tier: String, quality: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignConstants.relatedSpacing) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(tier)
                .font(.headline)
                .foregroundColor(color == .secondary ? .primary : color)

            Text(quality)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extension (Legacy Support)

extension View {
    /// Presents an upgrade prompt sheet when a premium quality feature is blocked.
    ///
    /// This replaces the previous alert-based modifier with a sheet presentation.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control sheet visibility
    ///   - promptInfo: The upgrade prompt information (message and optional URL)
    ///   - onUpgrade: Action called when user taps "Try Premium"
    /// - Returns: A view with the upgrade prompt sheet attached
    func upgradePrompt(
        isPresented: Binding<Bool>,
        promptInfo: UpgradePromptInfo?,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            UpgradePromptSheet(
                promptInfo: promptInfo,
                onUpgrade: onUpgrade,
                onDismiss: { isPresented.wrappedValue = false }
            )
        }
    }
}

// MARK: - Previews

#Preview("Upgrade Prompt Sheet - Light") {
    UpgradePromptSheet(
        promptInfo: UpgradePromptInfo(
            message: "Try our Premium version to download in high quality",
            upgradeURL: URL(string: "https://example.com/upgrade")
        ),
        onUpgrade: { print("Upgrade tapped") },
        onDismiss: { print("Dismiss tapped") }
    )
    .environment(\.colorScheme, .light)
}

#Preview("Upgrade Prompt Sheet - Dark") {
    UpgradePromptSheet(
        promptInfo: UpgradePromptInfo(
            message: "Try our Premium version to download in high quality",
            upgradeURL: URL(string: "https://example.com/upgrade")
        ),
        onUpgrade: { print("Upgrade tapped") },
        onDismiss: { print("Dismiss tapped") }
    )
    .environment(\.colorScheme, .dark)
}

#Preview("Upgrade Prompt Sheet - No URL") {
    UpgradePromptSheet(
        promptInfo: UpgradePromptInfo(
            message: "Premium features are not yet available in your region.",
            upgradeURL: nil
        ),
        onUpgrade: { print("Upgrade tapped") },
        onDismiss: { print("Dismiss tapped") }
    )
}
