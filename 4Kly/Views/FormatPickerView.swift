//
//  FormatPickerView.swift
//  YTMac
//
//  Picker for selecting download output format (MP4 video or MP3 audio)
//

import SwiftUI

/// A custom segmented picker for selecting the download output format.
///
/// Uses accent blue for the selected segment (matching the Download button).
/// MP4 downloads video + audio; MP3 extracts audio only.
struct FormatPickerView: View {
    
    // MARK: - Properties
    
    @Binding var selectedFormat: DownloadFormat
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DownloadFormat.allCases, id: \.self) { format in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFormat = format
                    }
                } label: {
                    Text(format.displayName)
                        .font(.system(size: 12, weight: selectedFormat == format ? .semibold : .regular))
                        .foregroundColor(selectedFormat == format ? .white : .secondary)
                        .frame(width: 46, height: 24)
                        .background(
                            selectedFormat == format
                                ? RoundedRectangle(cornerRadius: 5).fill(Color.accentColor)
                                : RoundedRectangle(cornerRadius: 5).fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.primary.opacity(0.08))
        )
        .accessibilityLabel("Output format selection")
    }
}

// MARK: - Preview

#Preview("Format Picker") {
    @Previewable @State var format: DownloadFormat = .mp4
    
    VStack(spacing: 20) {
        FormatPickerView(selectedFormat: $format)
        Text("Selected: \(format.displayName)")
    }
    .frame(width: 300, height: 100)
}
