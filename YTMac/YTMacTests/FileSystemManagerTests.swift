//
//  FileSystemManagerTests.swift
//  YTMacTests
//
//  Created by YTMac Developer
//

import XCTest
@testable import YTMac

final class FileSystemManagerTests: XCTestCase {
    
    var fileSystemManager: FileSystemManager!
    
    override func setUp() {
        super.setUp()
        fileSystemManager = FileSystemManager.shared
    }
    
    // MARK: - Application Support Directory Tests
    
    func testEnsureAppSupportDirectory_ReturnsValidURL() throws {
        // When
        let appSupportURL = try fileSystemManager.ensureAppSupportDirectory()
        
        // Then
        XCTAssertTrue(appSupportURL.path.hasSuffix("Library/Application Support/YTMac"),
                     "Should return path ending with Library/Application Support/YTMac")
        XCTAssertTrue(FileManager.default.fileExists(atPath: appSupportURL.path),
                     "Directory should exist after calling ensureAppSupportDirectory")
    }
    
    func testEnsureAppSupportDirectory_CreatesDirectoryIfNotExists() throws {
        // Given
        let expectedURL = try fileSystemManager.ensureAppSupportDirectory()
        
        // When - Call again to ensure idempotency
        let secondURL = try fileSystemManager.ensureAppSupportDirectory()
        
        // Then
        XCTAssertEqual(expectedURL, secondURL,
                      "Should return same URL on multiple calls")
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path),
                     "Directory should still exist")
    }
    
    func testEnsureAppSupportDirectory_CreatesIntermediateDirectories() throws {
        // When
        let appSupportURL = try fileSystemManager.ensureAppSupportDirectory()
        
        // Then - Check that parent directories exist
        let parentURL = appSupportURL.deletingLastPathComponent()
        XCTAssertTrue(FileManager.default.fileExists(atPath: parentURL.path),
                     "Parent directory (Application Support) should exist")
    }
    
    // MARK: - Logs Directory Tests
    
    func testEnsureLogsDirectory_ReturnsValidURL() throws {
        // When
        let logsURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then
        XCTAssertTrue(logsURL.path.hasSuffix("Library/Logs/YTMac"),
                     "Should return path ending with Library/Logs/YTMac")
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsURL.path),
                     "Directory should exist after calling ensureLogsDirectory")
    }
    
    func testEnsureLogsDirectory_CreatesDirectoryIfNotExists() throws {
        // Given
        let expectedURL = try fileSystemManager.ensureLogsDirectory()
        
        // When - Call again to ensure idempotency
        let secondURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then
        XCTAssertEqual(expectedURL, secondURL,
                      "Should return same URL on multiple calls")
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path),
                     "Directory should still exist")
    }
    
    func testEnsureLogsDirectory_CreatesIntermediateDirectories() throws {
        // When
        let logsURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then - Check that intermediate directories exist
        let logsParent = logsURL.deletingLastPathComponent() // Logs/
        let libraryParent = logsParent.deletingLastPathComponent() // Library/
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsParent.path),
                     "Logs directory should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: libraryParent.path),
                     "Library directory should exist")
    }
    
    // MARK: - Path Verification Tests
    
    func testAppSupportAndLogsDirectories_AreDifferent() throws {
        // When
        let appSupportURL = try fileSystemManager.ensureAppSupportDirectory()
        let logsURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then
        XCTAssertNotEqual(appSupportURL, logsURL,
                         "Application Support and Logs directories should be different")
    }
    
    func testDirectories_AreWritable() throws {
        // When
        let appSupportURL = try fileSystemManager.ensureAppSupportDirectory()
        let logsURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then - Try to create a test file in each directory
        let testFileInAppSupport = appSupportURL.appendingPathComponent("test.txt")
        let testFileInLogs = logsURL.appendingPathComponent("test.log")
        
        XCTAssertNoThrow(try "test".write(to: testFileInAppSupport, atomically: true, encoding: .utf8),
                        "Should be able to write to Application Support directory")
        XCTAssertNoThrow(try "test".write(to: testFileInLogs, atomically: true, encoding: .utf8),
                        "Should be able to write to Logs directory")
        
        // Cleanup
        try? FileManager.default.removeItem(at: testFileInAppSupport)
        try? FileManager.default.removeItem(at: testFileInLogs)
    }
    
    // MARK: - Edge Case Tests
    
    func testEnsureAppSupportDirectory_HandlesExpectedHomeDirectory() throws {
        // When
        let appSupportURL = try fileSystemManager.ensureAppSupportDirectory()
        
        // Then - Verify it's in the user's home directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertTrue(appSupportURL.path.hasPrefix(homeDirectory.path),
                     "Application Support directory should be in user's home directory")
    }
    
    func testEnsureLogsDirectory_HandlesExpectedHomeDirectory() throws {
        // When
        let logsURL = try fileSystemManager.ensureLogsDirectory()
        
        // Then - Verify it's in the user's home directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertTrue(logsURL.path.hasPrefix(homeDirectory.path),
                     "Logs directory should be in user's home directory")
    }
}
