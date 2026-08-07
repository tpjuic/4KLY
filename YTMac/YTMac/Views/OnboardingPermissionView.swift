//
//  OnboardingPermissionView.swift
//  YTMac
//
//  First-launch sheet for folder permission request.
//  Implements Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
//

import SwiftUI

// MARK: - OnboardingPermissionView

/// A sheet view presented on first launch to request download folder access.
///
/// Displays a friendly explanation of why folder access is needed, shows the
/// current download folder path, and provides options to choose a custom folder
/// or use the default Downloads location.
struct OnboardingPermissionView: View {
    
    // MARK: - Properties
    
    /// Controls sheet presentation
    @Binding var isPresented: Bool
    
    /// The current download folder path displayed to the user
    let downloadFolderPath: String
    
    /// Called when the user taps "Choose Folder" to grant access
    let onGrantAccess: () -> Void
    
    /// Called when the user taps "Use Default (Downloads)" to skip
    let onSkip: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: DesignConstants.baseSpacing * 1.5) {
            // SF Symbol illustration
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .padding(.top, DesignConstants.baseSpacing * 2)
            
            // Headline
            Text("Where should we save your videos?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Body explanation
            Text("YTMac needs access to a folder on your Mac to save downloaded videos. You can pick any folder you like, or use your Downloads folder.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignConstants.baseSpacing)
            
            // Current folder path
            HStack(spacing: DesignConstants.relatedSpacing) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.secondary)
                Text(downloadFolderPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, DesignConstants.baseSpacing)
            .padding(.vertical, DesignConstants.relatedSpacing)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                    .fill(Color.gray.opacity(0.1))
            )
            
            Spacer()
            
            // Buttons
            VStack(spacing: DesignConstants.relatedSpacing) {
                // Primary: Choose Folder
                Button(action: {
                    onGrantAccess()
                    isPresented = false
                }) {
                    Text("Choose Folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // Secondary: Use Default
                Button(action: {
                    onSkip()
                    isPresented = false
                }) {
                    Text("Use Default (Downloads)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.bottom, DesignConstants.baseSpacing * 2)
        }
        .padding(.horizontal, DesignConstants.baseSpacing * 2)
        .frame(width: 420, height: 440)
    }
}

// MARK: - Previews

#Preview("Onboarding Permission") {
    @Previewable @State var isPresented = true
    
    OnboardingPermissionView(
        isPresented: $isPresented,
        downloadFolderPath: "~/Downloads",
        onGrantAccess: { print("Grant access tapped") },
        onSkip: { print("Skip tapped") }
    )
}

#Preview("Long Path") {
    @Previewable @State var isPresented = true
    
    OnboardingPermissionView(
        isPresented: $isPresented,
        downloadFolderPath: "/Users/username/Documents/My Videos/YouTube Downloads",
        onGrantAccess: { print("Grant access tapped") },
        onSkip: { print("Skip tapped") }
    )
}

#Preview("Dark Mode") {
    @Previewable @State var isPresented = true
    
    OnboardingPermissionView(
        isPresented: $isPresented,
        downloadFolderPath: "~/Downloads",
        onGrantAccess: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}
