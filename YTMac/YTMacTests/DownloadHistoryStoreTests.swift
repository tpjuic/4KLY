//
//  DownloadHistoryStoreTests.swift
//  YTMacTests
//
//  Unit tests for DownloadHistoryStore
//  Validates Requirements 6.1, 6.2, 6.4, 6.5, 6.6
//

import XCTest
import SwiftData
@testable import YTMac

@MainActor
final class DownloadHistoryStoreTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var store: DownloadHistoryStore!
    
    override func setUp() async throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DownloadHistoryItem.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        store = DownloadHistoryStore(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        store = nil
    }
    
    // MARK: - Save Tests
    
    func testSaveCompletedDownload() throws {
        // Requirement 6.1: Store completed downloads with metadata
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Test Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4")),
            completedAt: Date(),
            outputPath: URL(fileURLWithPath: "/tmp/test.mp4")
        )
        
        try store.saveDownload(job)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].url, job.url)
        XCTAssertEqual(items[0].title, job.title)
        XCTAssertEqual(items[0].quality, job.quality.displayName)
        XCTAssertEqual(items[0].outputPath, job.outputPath?.path)
        XCTAssertEqual(items[0].status, "completed")
        XCTAssertNil(items[0].errorMessage)
    }
    
    func testSaveFailedDownload() throws {
        // Requirement 6.2: Store failed downloads with error information
        let errorMessage = "Network connection failed"
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Failed Video",
            quality: .standard480p,
            status: .failed(error: errorMessage),
            completedAt: Date(),
            errorMessage: errorMessage
        )
        
        try store.saveDownload(job)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].status, "failed")
        XCTAssertEqual(items[0].errorMessage, errorMessage)
        XCTAssertNil(items[0].outputPath)
    }
    
    func testSaveDownloadWithEmptyTitle() throws {
        // Edge case: Handle empty title
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "",
            quality: .standard360p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try store.saveDownload(job)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Unknown Title")
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAllReverseChronological() throws {
        // Requirement 6.3, 6.4: Fetch history in reverse chronological order
        let now = Date()
        let job1 = DownloadJob(
            url: "https://example.com/video1",
            title: "Video 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4")),
            createdAt: now.addingTimeInterval(-3600) // 1 hour ago
        )
        let job2 = DownloadJob(
            url: "https://example.com/video2",
            title: "Video 2",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4")),
            createdAt: now.addingTimeInterval(-1800) // 30 minutes ago
        )
        let job3 = DownloadJob(
            url: "https://example.com/video3",
            title: "Video 3",
            quality: .standard360p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test3.mp4")),
            createdAt: now // now
        )
        
        try store.saveDownload(job1)
        try store.saveDownload(job2)
        try store.saveDownload(job3)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 3)
        // Should be in reverse chronological order (newest first)
        XCTAssertEqual(items[0].title, "Video 3")
        XCTAssertEqual(items[1].title, "Video 2")
        XCTAssertEqual(items[2].title, "Video 1")
    }
    
    func testFetchAllEmpty() throws {
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 0)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteAll() throws {
        // Requirement 6.5: Clear all download history
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
        
        try store.saveDownload(job1)
        try store.saveDownload(job2)
        
        var items = try store.fetchAll()
        XCTAssertEqual(items.count, 2)
        
        try store.deleteAll()
        
        items = try store.fetchAll()
        XCTAssertEqual(items.count, 0)
    }
    
    func testDeleteItem() throws {
        // Requirement 6.6: Delete individual history entries
        let job1 = DownloadJob(
            id: UUID(),
            url: "https://example.com/video1",
            title: "Video 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4"))
        )
        let job2 = DownloadJob(
            id: UUID(),
            url: "https://example.com/video2",
            title: "Video 2",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4"))
        )
        
        try store.saveDownload(job1)
        try store.saveDownload(job2)
        
        var items = try store.fetchAll()
        XCTAssertEqual(items.count, 2)
        
        try store.deleteItem(id: job1.id)
        
        items = try store.fetchAll()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].id, job2.id)
        XCTAssertEqual(items[0].title, "Video 2")
    }
    
    func testDeleteNonExistentItem() throws {
        // Edge case: Deleting non-existent item should not throw
        let job = DownloadJob(
            url: "https://example.com/video",
            title: "Video",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test.mp4"))
        )
        
        try store.saveDownload(job)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 1)
        
        // Try to delete a different ID
        try store.deleteItem(id: UUID())
        
        // Should still have the original item
        let remainingItems = try store.fetchAll()
        XCTAssertEqual(remainingItems.count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveMultipleJobsWithSameURL() throws {
        // Should allow multiple jobs with same URL (different downloads over time)
        let url = "https://example.com/video"
        let job1 = DownloadJob(
            url: url,
            title: "Video Download 1",
            quality: .standard720p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test1.mp4"))
        )
        let job2 = DownloadJob(
            url: url,
            title: "Video Download 2",
            quality: .standard480p,
            status: .completed(path: URL(fileURLWithPath: "/tmp/test2.mp4"))
        )
        
        try store.saveDownload(job1)
        try store.saveDownload(job2)
        
        let items = try store.fetchAll()
        XCTAssertEqual(items.count, 2)
    }
}
