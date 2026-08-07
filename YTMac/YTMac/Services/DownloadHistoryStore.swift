//
//  DownloadHistoryStore.swift
//  YTMac
//
//  SwiftData-based persistence service for download history.
//  Implements Requirements 6.1, 6.2, 6.4, 6.5, 6.6
//

import Foundation
import SwiftData

/// Service for persisting and retrieving download history using SwiftData.
/// Thread-safe via @MainActor isolation.
@MainActor
class DownloadHistoryStore: ObservableObject {
    private let modelContext: ModelContext
    
    /// Initialize the store with a SwiftData model context
    /// - Parameter modelContext: The SwiftData context for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Save Operations
    
    /// Save a completed or failed download job to history.
    /// Requirement 6.1: Store completed downloads with metadata
    /// Requirement 6.2: Store failed downloads with error information
    /// - Parameter job: The download job to persist
    /// - Throws: SwiftData errors if save fails
    func saveDownload(_ job: DownloadJob) throws {
        let item = DownloadHistoryItem(
            id: job.id,
            url: job.url,
            title: job.title.isEmpty ? "Unknown Title" : job.title,
            quality: job.quality.displayName,
            format: job.format.displayName,
            outputPath: job.outputPath?.path,
            status: job.status.historyStatus,
            errorMessage: job.errorMessage,
            createdAt: job.createdAt,
            completedAt: job.completedAt
        )
        
        modelContext.insert(item)
        try modelContext.save()
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all download history items in reverse chronological order.
    /// Requirement 6.3: Display download history
    /// Requirement 6.4: Persist data to disk using local database
    /// - Returns: Array of history items, newest first
    /// - Throws: SwiftData errors if fetch fails
    func fetchAll() throws -> [DownloadHistoryItem] {
        let descriptor = FetchDescriptor<DownloadHistoryItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Delete Operations
    
    /// Delete all download history items.
    /// Requirement 6.5: Allow users to clear download history
    /// - Throws: SwiftData errors if delete fails
    func deleteAll() throws {
        try modelContext.delete(model: DownloadHistoryItem.self)
        try modelContext.save()
    }
    
    /// Delete a specific download history item by ID.
    /// Requirement 6.6: Allow users to manage individual history entries
    /// - Parameter id: The unique identifier of the item to delete
    /// - Throws: SwiftData errors if delete fails
    func deleteItem(id: UUID) throws {
        let descriptor = FetchDescriptor<DownloadHistoryItem>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let item = try modelContext.fetch(descriptor).first {
            modelContext.delete(item)
            try modelContext.save()
        }
    }
}
