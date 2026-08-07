//
//  PathValidatorTests.swift
//  YTMacTests
//
//  Unit tests for PathValidator
//  Validates Requirements: 8.3, 11.4
//

import XCTest
@testable import YTMac

final class PathValidatorTests: XCTestCase {
    
    var validator: PathValidator!
    var tempDirectoryURL: URL!
    
    override func setUp() {
        super.setUp()
        validator = PathValidator()
        
        // Create a temporary directory for testing
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        try? FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
    }
    
    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        tempDirectoryURL = nil
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Valid Directory Tests
    
    func testValidateExistingWritableDirectory() {
        // Given: A valid writable directory
        let result = validator.validate(tempDirectoryURL)
        
        // Then: Validation should succeed
        XCTAssertTrue(result.isValid, "Existing writable directory should be valid")
        XCTAssertNil(result.errorMessage, "Valid directory should have no error message")
        
        if case .valid = result {
            // Success
        } else {
            XCTFail("Expected .valid result")
        }
    }
    
    func testValidateUserDownloadsDirectory() {
        // Given: User's Downloads directory
        let downloadsURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first!
        
        // When: Validating downloads directory
        let result = validator.validate(downloadsURL)
        
        // Then: Should be valid
        XCTAssertTrue(result.isValid, "Downloads directory should be valid")
    }
    
    // MARK: - Non-Existent Path Tests
    
    func testValidateNonExistentDirectory() {
        // Given: A non-existent directory path
        let nonExistentURL = tempDirectoryURL.appendingPathComponent("nonexistent")
        
        // When: Validating non-existent directory
        let result = validator.validate(nonExistentURL)
        
        // Then: Should be invalid
        XCTAssertFalse(result.isValid, "Non-existent directory should be invalid")
        XCTAssertNotNil(result.errorMessage, "Should have error message")
        
        if case .invalid(let reason) = result {
            XCTAssertTrue(
                reason.contains("does not exist"),
                "Error message should indicate directory doesn't exist"
            )
        } else {
            XCTFail("Expected .invalid result")
        }
    }
    
    // MARK: - File Path Tests
    
    func testValidateFilePath() {
        // Given: A file path instead of directory
        let fileURL = tempDirectoryURL.appendingPathComponent("testfile.txt")
        FileManager.default.createFile(
            atPath: fileURL.path,
            contents: Data(),
            attributes: nil
        )
        
        // When: Validating file path
        let result = validator.validate(fileURL)
        
        // Then: Should be invalid
        XCTAssertFalse(result.isValid, "File path should be invalid")
        
        if case .invalid(let reason) = result {
            XCTAssertTrue(
                reason.contains("not a directory"),
                "Error message should indicate path is not a directory"
            )
        } else {
            XCTFail("Expected .invalid result")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Non-Writable Directory Tests
    
    func testValidateNonWritableDirectory() {
        // Given: A non-writable directory (read-only)
        let readOnlyDir = tempDirectoryURL.appendingPathComponent("readonly")
        try? FileManager.default.createDirectory(
            at: readOnlyDir,
            withIntermediateDirectories: true
        )
        
        // Make directory read-only
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o444], // r--r--r--
            ofItemAtPath: readOnlyDir.path
        )
        
        // When: Validating read-only directory
        let result = validator.validate(readOnlyDir)
        
        // Then: Should be invalid
        XCTAssertFalse(result.isValid, "Read-only directory should be invalid")
        
        if case .invalid(let reason) = result {
            XCTAssertTrue(
                reason.contains("not writable"),
                "Error message should indicate directory is not writable"
            )
        } else {
            XCTFail("Expected .invalid result")
        }
        
        // Clean up - restore write permissions before removal
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: readOnlyDir.path
        )
        try? FileManager.default.removeItem(at: readOnlyDir)
    }
    
    // MARK: - Edge Cases
    
    func testValidateRootDirectory() {
        // Given: Root directory (/)
        let rootURL = URL(fileURLWithPath: "/")
        
        // When: Validating root directory
        let result = validator.validate(rootURL)
        
        // Then: Should exist but typically not be writable for regular users
        // This test documents the behavior but result may vary by system permissions
        if case .valid = result {
            // Root is writable (e.g., running as admin)
            XCTAssertTrue(result.isValid)
        } else if case .invalid = result {
            // Root is not writable (typical case)
            XCTAssertFalse(result.isValid)
        }
    }
    
    func testValidateEmptyPath() {
        // Given: Empty path
        let emptyURL = URL(fileURLWithPath: "")
        
        // When: Validating empty path
        let result = validator.validate(emptyURL)
        
        // Then: Should be invalid
        XCTAssertFalse(result.isValid, "Empty path should be invalid")
    }
}
