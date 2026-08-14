//
//  HistoryView.swift
//  YTMac
//
//  View displaying download history with clear functionality
//  Implements Requirements: 6.1, 6.3, 6.5, 7.1, 7.4, 7.5, 10.2, 10.3, 10.4, 13.1
//

import SwiftUI

/// A view that displays the user's download history.
///
/// Shows a scrollable list of past downloads using HistoryCardView for each item,
/// with toolbar actions for clearing history and an empty state
/// when no history exists.
struct HistoryView: View {
    
    // MARK: - Properties
    
    /// ViewModel managing history data and operations
    @ObservedObject var viewModel: HistoryViewModel
    
    /// Optional format filter ("MP3" for Music, "MP4" for Videos, nil for all)
    var formatFilter: String? = nil
    
    /// Filtered history items based on format
    private var filteredItems: [DownloadHistoryItem] {
        guard let filter = formatFilter else {
            return viewModel.historyItems
        }
        return viewModel.historyItems.filter { ($0.format ?? "MP4") == filter }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if filteredItems.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(duration: DesignConstants.animationDuration), value: filteredItems.count)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.clearHistory()
                    }
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(viewModel.historyItems.isEmpty)
                .accessibilityLabel("Clear History")
                .accessibilityHint("Removes all items from download history")
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }
    
    // MARK: - Private Views
    
    /// Loading indicator displayed while history is being fetched
    private var loadingView: some View {
        VStack(spacing: DesignConstants.relatedSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Loading history…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading download history")
    }
    
    /// Empty state displayed when no download history exists
    private var emptyStateView: some View {
        VStack(spacing: DesignConstants.relatedSpacing) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: DesignConstants.emptyStateIconSize))
                .foregroundColor(.secondary)
            
            Text("No download history")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Completed and failed downloads will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No download history")
    }
    
    /// Error view displayed when loading or operations fail
    private func errorView(message: String) -> some View {
        VStack(spacing: DesignConstants.relatedSpacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: DesignConstants.emptyStateIconSize))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadHistory()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
    
    /// Scrollable list of history items using HistoryCardView cards
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: DesignConstants.relatedSpacing) {
                ForEach(filteredItems) { item in
                    HistoryCardView(item: item) {
                        Task {
                            await viewModel.redownload(item: item)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteItem(id: item.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(DesignConstants.baseSpacing)
        }
        .accessibilityLabel("Download history list")
    }
}
