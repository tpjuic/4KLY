//
//  QualityPickerView.swift
//  YTMac
//
//  Picker displaying video quality options with premium badges
//  Implements Requirements: 2.2, 7.4
//

import SwiftUI

/// A picker view for selecting video download quality.
///
/// Displays all `VideoQuality` cases with their display names.
/// Premium quality options (1080p+) are visually indicated with a
/// crown badge to inform users these require an upgrade.
struct QualityPickerView: View {
    
    // MARK: - Properties
    
    /// Binding to the currently selected video quality
    @Binding var selectedQuality: VideoQuality
    
    // MARK: - Body
    
    var body: some View {
        Picker("Quality", selection: $selectedQuality) {
            ForEach(VideoQuality.allCases, id: \.self) { quality in
                qualityLabel(for: quality)
                    .tag(quality)
            }
        }
        .accessibilityLabel("Video quality selection")
    }
    
    // MARK: - Private Views
    
    /// Creates a label for a quality option, adding a premium badge for high quality
    @ViewBuilder
    private func qualityLabel(for quality: VideoQuality) -> some View {
        if quality.isPremium {
            Label {
                Text(quality.displayName)
            } icon: {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                    .font(.caption2)
            }
        } else {
            Text(quality.displayName)
        }
    }
}

// MARK: - VideoQuality Premium Extension

extension VideoQuality {
    /// Whether this quality level is a premium (high quality) option
    var isPremium: Bool {
        resolution > 720
    }
}

// MARK: - Preview

#Preview("Quality Picker") {
    @Previewable @State var quality: VideoQuality = .standard720p
    
    Form {
        QualityPickerView(selectedQuality: $quality)
    }
    .frame(width: 300, height: 200)
}
