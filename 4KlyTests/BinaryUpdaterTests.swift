//
//  BinaryUpdaterTests.swift
//  YTMacTests
//
//  Tests for BinaryUpdater actor
//  Validates Requirements: 3.1, 3.2
//

import XCTest
@testable import _4Kly

final class BinaryUpdaterTests: XCTestCase {
    
    var testBinaryPath: URL!
    
    override func setUp() {
        super.setUp()
        
        // Get the expected binary path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        testBinaryPath = appSupport.appendingPathComponent("4Kly").appendingPathComponent("yt-dlp")
    }
    
    override func tearDown() {
        // Clean up test binary if it exists
        if FileManager.default.fileExists(atPath: testBinaryPath.path) {
            try? FileManager.default.removeItem(at: testBinaryPath)
        }
        super.tearDown()
    }
    
    // MARK: - ensureBinaryExists Tests
    
    func testEnsureBinaryExists_WhenBinaryExists_ReturnsPath() async throws {
        // Given - Create a dummy binary file with mock GitHub API
        let mockGitHubAPI = MockGitHubAPIClient()
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        try FileSystemManager.shared.ensureAppSupportDirectory()
        try "dummy binary".write(to: testBinaryPath, atomically: true, encoding: .utf8)
        
        // When
        let resultPath = try await binaryUpdater.ensureBinaryExists()
        
        // Then
        XCTAssertEqual(resultPath, testBinaryPath, "Should return existing binary path")
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultPath.path), "Binary should exist")
        XCTAssertFalse(await mockGitHubAPI.fetchLatestReleaseCalled, "Should not call GitHub API when binary exists")
    }
    
    func testEnsureBinaryExists_WhenBinaryExists_DoesNotDownload() async throws {
        // Given - Create binary and mock API
        let mockGitHubAPI = MockGitHubAPIClient()
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        try FileSystemManager.shared.ensureAppSupportDirectory()
        let originalContent = "original binary content"
        try originalContent.write(to: testBinaryPath, atomically: true, encoding: .utf8)
        
        // When
        _ = try await binaryUpdater.ensureBinaryExists()
        
        // Then - Content should remain unchanged
        let finalContent = try String(contentsOf: testBinaryPath, encoding: .utf8)
        XCTAssertEqual(finalContent, originalContent, "Binary content should not change")
    }
    
    func testEnsureBinaryExists_WhenGitHubAPIFails_ThrowsBinaryError() async throws {
        // Given - Ensure binary does NOT exist
        if FileManager.default.fileExists(atPath: testBinaryPath.path) {
            try FileManager.default.removeItem(at: testBinaryPath)
        }
        
        // Configure mock to fail
        let mockGitHubAPI = MockGitHubAPIClient()
        await mockGitHubAPI.setShouldSucceed(false)
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        // When/Then
        do {
            _ = try await binaryUpdater.ensureBinaryExists()
            XCTFail("Should throw BinaryError")
        } catch let error as BinaryError {
            // Verify it's a download failed error
            if case .downloadFailed = error {
                XCTAssertTrue(true, "Correctly threw BinaryError.downloadFailed")
            } else {
                XCTFail("Should throw BinaryError.downloadFailed, got \(error)")
            }
        } catch {
            XCTFail("Should throw BinaryError, got \(type(of: error))")
        }
    }
    
    func testEnsureBinaryExists_ReturnsCorrectPath() async throws {
        // Given - Create binary with mock API
        let mockGitHubAPI = MockGitHubAPIClient()
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        try FileSystemManager.shared.ensureAppSupportDirectory()
        try "test".write(to: testBinaryPath, atomically: true, encoding: .utf8)
        
        // When
        let resultPath = try await binaryUpdater.ensureBinaryExists()
        
        // Then
        XCTAssertTrue(resultPath.path.contains("Library/Application Support/4Kly/yt-dlp"),
                     "Should return correct path in Application Support")
        XCTAssertEqual(resultPath.lastPathComponent, "yt-dlp", 
                      "Binary filename should be 'yt-dlp'")
    }
    
    // MARK: - shouldCheckForUpdate Tests
    
    func testShouldCheckForUpdate_WhenNeverChecked_ReturnsTrue() async {
        // Given
        let mockGitHubAPI = MockGitHubAPIClient()
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        // When
        let shouldCheck = await binaryUpdater.shouldCheckForUpdate()
        
        // Then
        XCTAssertTrue(shouldCheck, "Should check for update when never checked before")
    }
    
    // MARK: - Edge Cases
    
    func testEnsureBinaryExists_BinaryPathFormat() async throws {
        // Given
        let mockGitHubAPI = MockGitHubAPIClient()
        let binaryUpdater = BinaryUpdater(githubAPI: mockGitHubAPI)
        
        try FileSystemManager.shared.ensureAppSupportDirectory()
        try "test".write(to: testBinaryPath, atomically: true, encoding: .utf8)
        
        // When
        let path = try await binaryUpdater.ensureBinaryExists()
        
        // Then
        let pathComponents = path.pathComponents
        XCTAssertTrue(pathComponents.contains("4Kly"), "Path should contain 4Kly directory")
        XCTAssertTrue(pathComponents.contains("Application Support"), "Path should be in Application Support")
        XCTAssertEqual(path.lastPathComponent, "yt-dlp", "Binary name should be yt-dlp")
    }
}

// MARK: - Mock GitHub API Client

/// Mock implementation of GitHubAPIClient for testing
actor MockGitHubAPIClient {
    private var shouldSucceed = true
    var fetchLatestReleaseCalled = false
    
    func setShouldSucceed(_ succeed: Bool) {
        shouldSucceed = succeed
    }
    
    func fetchLatestRelease() async throws -> UpdateInfo {
        fetchLatestReleaseCalled = true
        
        if !shouldSucceed {
            throw GitHubAPIClient.APIError.networkError(
                NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock network error"])
            )
        }
        
        // Return mock update info with file:// URL
        // Note: This won't actually be downloaded in the successful case
        // because ensureBinaryExists() returns early when binary exists
        return UpdateInfo(
            currentVersion: "2024.01.01",
            latestVersion: "2024.03.10",
            downloadURL: URL(string: "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_macos")!,
            releaseNotes: "Mock release notes"
        )
    }
}
