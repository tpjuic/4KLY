//
//  HistoryViewModelTests.swift
//  YTMacTests
//
//  Unit tests for HistoryViewModel
//  Validates Requirements 6.3, 6.4, 6.5
//

import XCTest
import SwiftData
@testable import YTMac

// MARK: - Mock DownloadManager

/// Mock DownloadManager for testing HistoryViewModel
/// Simulates download submission without actual network or process execution
actor MockDownloadManager {
    var submitDownloadCalled = false
    var submittedURL: String?
    var submittedQuality: VideoQuality?
    var shouldThrowQualityGateError = false
    var shouldThrowGenericError = false
    
    func submitDownload(url: String, quality: VideoQuality) async throws -> UUID {
        submitDownloadCalled = true
        submittedURL = url
        submittedQuality = quality
        
        if shouldThrowQualityGateError {
            let upgradePrompt = UpgradePromptInfo(
                message: "Try our Premium version to download in high quality",
                upgradeURL: nil
            )
            throw QualityGateError.qualityBlocked(prompt: upgradePrompt)
        }
        
        if shouldThrowGenericError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock download error"])
        }
        
        return UUID()
    }
}

// MARK: - HistoryViewModel Tests

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var historyStore: DownloadHistoryStore!
    var mockDownloadManager: MockDownloadManager!
    var viewModel: HistoryViewModel!
    
    override func setUp() async throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DownloadHistoryItem.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        historyStore = DownloadHistoryStore(modelContext: modelContext)
        mockDownloadManager = MockDownloadManager()
        viewModel = HistoryViewModel(historyStore: historyStore, downloadManager: mockDownloadManager)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        historyStore = nil
        mockDownloadManager = nil
        viewModel = nil
    }
    
    // MARK: - loadHistory() Tests
    
    func testLoadHistorySuccess() async throws {
        // Requirements 6.3, 6.4: Load and display persisted download history
        
        // Setup: Add some items to the store
        let job1 = DownloadJob(
            url: "https://example.com/video1",
            title: "Test Video 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4"))
        )
        let job2 = DownloadJob(
            url: "https://example.com/video2",
            title: "Test Video 2",
            quality: .standard480p,
            status: .failed(error: "Network error"),
            errorMessage: "Network error"
        )
        
        try historyStore.saveDownload(job1)
        try historyStore.saveDownload(job2)
        
        // Verify initial state
        XCTAssertEqual(viewModel.historyItems.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Execute
        await viewModel.loadHistory()
        
        // Verify
        XCTAssertEqual(viewModel.historyItems.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify items are loaded
        let titles = viewModel.historyItems.map { $0.title }
        XCTAssertTrue(titles.contains("Test Video 1"))
        XCTAssertTrue(titles.contains("Test Video 2"))
    }
    
    func testLoadHistoryEmpty() async throws {
        // Requirements 6.3, 6.4: Handle empty history gracefully
        
        // Verify initial state
        XCTAssertEqual(viewModel.historyItems.count, 0)
        
        // Execute
        await viewModel.loadHistory()
        
        // Verify
        XCTAssertEqual(viewModel.historyItems.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadHistorySetIsLoadingFlag() async throws {
        // Requirement 6.3: Set isLoading flag during load
        
        // Add an item to load
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        try historyStore.saveDownload(job)
        
        // Initial state
        XCTAssertFalse(viewModel.isLoading)
        
        // Execute
        await viewModel.loadHistory()
        
        // After completion, isLoading should be false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadHistoryClearsErrorMessage() async throws {
        // Requirement 6.4: Clear error message on new load
        
        // Setup: Set an error message
        viewModel.errorMessage = "Previous error"
        
        // Execute
        await viewModel.loadHistory()
        
        // Verify error message is cleared
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadHistoryOrder() async throws {
        // Requirements 6.3, 6.4: Items should be in reverse chronological order
        
        let now = Date()
        let job1 = DownloadJob(
            url: "https://example.com/video1",
            title: "Oldest",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4")),
            createdAt: now.addingTimeInterval(-3600) // 1 hour ago
        )
        let job2 = DownloadJob(
            url: "https://example.com/video2",
            title: "Middle",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4")),
            createdAt: now.addingTimeInterval(-1800) // 30 minutes ago
        )
        let job3 = DownloadJob(
            url: "https://example.com/video3",
            title: "Newest",
            quality: .standard360p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test3.mp4")),
            createdAt: now
        )
        
        try historyStore.saveDownload(job1)
        try historyStore.saveDownload(job2)
        try historyStore.saveDownload(job3)
        
        // Execute
        await viewModel.loadHistory()
        
        // Verify order (newest first)
        XCTAssertEqual(viewModel.historyItems.count, 3)
        XCTAssertEqual(viewModel.historyItems[0].title, "Newest")
        XCTAssertEqual(viewModel.historyItems[1].title, "Middle")
        XCTAssertEqual(viewModel.historyItems[2].title, "Oldest")
    }
    
    // MARK: - clearHistory() Tests
    
    func testClearHistorySuccess() async throws {
        // Requirement 6.5: Clear all download history
        
        // Setup: Add items
        let job1 = DownloadJob(
            url: "https://example.com/video1",
            title: "Video 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4"))
        )
        let job2 = DownloadJob(
            url: "https://example.com/video2",
            title: "Video 2",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4"))
        )
        
        try historyStore.saveDownload(job1)
        try historyStore.saveDownload(job2)
        
        // Load history first
        await viewModel.loadHistory()
        XCTAssertEqual(viewModel.historyItems.count, 2)
        
        // Execute
        await viewModel.clearHistory()
        
        // Verify
        XCTAssertEqual(viewModel.historyItems.count, 0)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify store is also empty
        let storeItems = try historyStore.fetchAll()
        XCTAssertEqual(storeItems.count, 0)
    }
    
    func testClearHistoryWhenEmpty() async throws {
        // Requirement 6.5: Handle clearing empty history
        
        // Execute
        await viewModel.clearHistory()
        
        // Verify
        XCTAssertEqual(viewModel.historyItems.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - deleteItem(id:) Tests
    
    func testDeleteItemSuccess() async throws {
        // Requirement 6.5: Delete a single item from download history
        
        // Setup: Add items
        let job1 = DownloadJob(
            url: "https://example.com/video1",
            title: "Video 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4"))
        )
        let job2 = DownloadJob(
            url: "https://example.com/video2",
            title: "Video 2",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4"))
        )
        let job3 = DownloadJob(
            url: "https://example.com/video3",
            title: "Video 3",
            quality: .standard360p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test3.mp4"))
        )
        
        try historyStore.saveDownload(job1)
        try historyStore.saveDownload(job2)
        try historyStore.saveDownload(job3)
        
        // Load history first
        await viewModel.loadHistory()
        XCTAssertEqual(viewModel.historyItems.count, 3)
        
        // Get the ID of the second item
        let itemToDelete = viewModel.historyItems.first { $0.title == "Video 2" }!
        let deleteId = itemToDelete.id
        
        // Execute
        await viewModel.deleteItem(id: deleteId)
        
        // Verify
        XCTAssertEqual(viewModel.historyItems.count, 2)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify the correct item was deleted
        let remainingTitles = viewModel.historyItems.map { $0.title }
        XCTAssertTrue(remainingTitles.contains("Video 1"))
        XCTAssertFalse(remainingTitles.contains("Video 2"))
        XCTAssertTrue(remainingTitles.contains("Video 3"))
        
        // Verify the item is also deleted from the store
        let storeItems = try historyStore.fetchAll()
        XCTAssertEqual(storeItems.count, 2)
        XCTAssertFalse(storeItems.contains { $0.id == deleteId })
    }
    
    func testDeleteItemRemovesFromUI() async throws {
        // Requirement 6.5: Verify item is removed from historyItems array
        
        // Setup: Add an item
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try historyStore.saveDownload(job)
        await viewModel.loadHistory()
        
        XCTAssertEqual(viewModel.historyItems.count, 1)
        let itemId = viewModel.historyItems[0].id
        
        // Execute
        await viewModel.deleteItem(id: itemId)
        
        // Verify UI is updated
        XCTAssertEqual(viewModel.historyItems.count, 0)
    }
    
    func testDeleteItemCallsStoreDelete() async throws {
        // Requirement 6.5: Verify DownloadHistoryStore.deleteItem is called
        
        // Setup: Add an item
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try historyStore.saveDownload(job)
        await viewModel.loadHistory()
        
        let itemId = viewModel.historyItems[0].id
        
        // Verify item exists in store
        let itemsBeforeDelete = try historyStore.fetchAll()
        XCTAssertEqual(itemsBeforeDelete.count, 1)
        
        // Execute
        await viewModel.deleteItem(id: itemId)
        
        // Verify item is removed from store
        let itemsAfterDelete = try historyStore.fetchAll()
        XCTAssertEqual(itemsAfterDelete.count, 0)
    }
    
    func testDeleteItemClearsErrorMessage() async throws {
        // Requirement 6.5: Verify error message is cleared on successful delete
        
        // Setup: Add an item and set an error message
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try historyStore.saveDownload(job)
        await viewModel.loadHistory()
        
        viewModel.errorMessage = "Previous error"
        let itemId = viewModel.historyItems[0].id
        
        // Execute
        await viewModel.deleteItem(id: itemId)
        
        // Verify error message is cleared
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteItemWithNonExistentId() async throws {
        // Requirement 6.5: Handle deletion of non-existent item gracefully
        
        // Setup: Add items
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try historyStore.saveDownload(job)
        await viewModel.loadHistory()
        
        XCTAssertEqual(viewModel.historyItems.count, 1)
        
        // Execute with non-existent ID
        let nonExistentId = UUID()
        await viewModel.deleteItem(id: nonExistentId)
        
        // Verify: No error, original item still exists
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.historyItems.count, 1)
    }
}
