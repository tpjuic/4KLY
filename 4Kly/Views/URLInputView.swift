//
//  URLInputView.swift
//  YTMac
//
//  Text input component for video URL(s) with multi-line support for batch downloads
//  Implements Requirements: 1.1, 7.4
//

import SwiftUI

/// A multi-line text input view for pasting video URLs.
///
/// Supports batch downloads by allowing users to paste multiple URLs,
/// one per line. Uses TextEditor for multi-line input with a placeholder
/// overlay when the input is empty.
struct URLInputView: View {
    
    // MARK: - Properties
    
    /// Binding to the URL input text, typically from DownloadViewModel.urlInput
    @Binding var urlInput: String
    
    /// Tracks whether the text editor is focused
    @FocusState private var isFocused: Bool
    
    /// External trigger to programmatically focus the input field (e.g., from ⌘N menu command)
    @Binding var shouldFocus: Bool
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // TextEditor for multi-line URL input
            TextEditor(text: $urlInput)
                .font(.system(.body, design: .monospaced))
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .accessibilityLabel("Video URL input")
                .accessibilityHint("Paste one or more video URLs, one per line, for batch downloading")
            
            // Placeholder text when input is empty
            if urlInput.isEmpty && !isFocused {
                Text("Paste video URL(s) here")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
        .padding(DesignConstants.relatedSpacing)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(DesignConstants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .stroke(isFocused ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .frame(minHeight: 60, maxHeight: 120)
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                isFocused = true
                shouldFocus = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty") {
    URLInputView(urlInput: .constant(""), shouldFocus: .constant(false))
        .padding()
        .frame(width: 500)
}

#Preview("With Single URL") {
    URLInputView(urlInput: .constant("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), shouldFocus: .constant(false))
        .padding()
        .frame(width: 500)
}

#Preview("With Multiple URLs") {
    URLInputView(urlInput: .constant("""
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    https://www.youtube.com/watch?v=abc123
    https://vimeo.com/12345678
    """), shouldFocus: .constant(false))
        .padding()
        .frame(width: 500)
}
