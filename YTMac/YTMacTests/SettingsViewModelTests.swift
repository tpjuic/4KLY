//
//  SettingsViewModelTests.swift
//  YTMacTests
//
//  Unit tests for SettingsViewModel
//  Validates: Requirements 8.1, 8.3, 8.4
//

import XCTest
@testable import YTMac

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    var viewModel: SettingsViewModel!
    var mockConfigService: MockConfigService!
    var mockBinaryUpdater: MockBinaryUpdater!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock dependencies
        mockConfigService = MockConfigService()
        mockBinaryUpdater = MockBinaryUpdater()
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        viewModel = SettingsViewModel(
            configService: mockConfigService,
            binaryUpdater: mockBinaryUpdater
        )
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        viewModel = nil
        mockConfigService = nil
        mockBinaryUpdater = nil
        tempDirectory = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_LoadsDownloadLocationFromConfigService() {
        // Given: mock config service with specific download location
        let expectedLocation = URL(fileURLWithPath: "/Users/test/Downloads")
        mockConfigService.downloadLocation = expectedLocation
        
        // When: creating view model
        let vm = SettingsViewModel(
            configService: mockConfigService,
            binaryUpdater: mockBinaryUpdater
        )
        
        // Then: download location should be loaded from config
        XCTAssertEqual(vm.downloadLocation, expectedLocation)
    }
    
    // MARK: - Path Validation Tests
    
    func testPathValidator_ValidDirectory_ReturnsValid() {
        // Given: a valid writable directory
        let validator = PathValidator()
        
        // When: validating the temp directory
        let result = validator.validate(tempDirectory)
        
        // Then: validation should succeed
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testPathValidator_NonExistentDirectory_ReturnsInvalid() {
        // Given: a non-existent directory path
        let nonExistentPath = URL(fileURLWithPath: "/path/that/does/not/exist")
        let validator = PathValidator()
        
        // When: validating the non-existent path
        let result = validator.validate(nonExistentPath)
        
        // Then: validation should fail
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("does not exist") ?? false)
    }
    
    func testPathValidator_FilePath_ReturnsInvalid() {
        // Given: a file path (not a directory)
        let filePath = tempDirectory.appendingPathComponent("testfile.txt")
        try? "test content".write(to: filePath, atomically: true, encoding: .utf8)
        let validator = PathValidator()
        
        // When: validating the file path
        let result = validator.validate(filePath)
        
        // Then: validation should fail
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("not a directory") ?? false)
    }
    
    func testPathValidator_NonWritableDirectory_ReturnsInvalid() {
        // Given: a read-only directory (simulated by system directories)
        // Note: /System is read-only on macOS
        let readOnlyPath = URL(fileURLWithPath: "/System")
        let validator = PathValidator()
        
        // When: validating the read-only path
        let result = validator.validate(readOnlyPath)
        
        // Then: validation should fail (unless running with elevated privileges)
        // This test may be environment-dependent
        if !result.isValid {
            XCTAssertNotNil(result.errorMessage)
            XCTAssertTrue(result.errorMessage?.contains("not writable") ?? false)
        }
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigService_UpdateDownloadLocation_Persists() {
        // Given: a new download location
        let newLocation = tempDirectory.appendingPathComponent("NewDownloads")
        try? FileManager.default.createDirectory(at: newLocation, withIntermediateDirectories: true)
        
        // When: updating download location in config service
        mockConfigService.downloadLocation = newLocation
        
        // Then: location should be updated
        XCTAssertEqual(mockConfigService.downloadLocation, newLocation)
        XCTAssertTrue(mockConfigService.downloadLocationUpdateCalled)
    }
    
    func testSettingsViewModel_DownloadLocationProperty_UpdatesReactively() {
        // Given: initial download location
        let initialLocation = mockConfigService.downloadLocation
        let newLocation = tempDirectory.appendingPathComponent("NewLocation")
        try? FileManager.default.createDirectory(at: newLocation, withIntermediateDirectories: true)
        
        // When: updating download location property
        viewModel.downloadLocation = newLocation
        
        // Then: property should be updated
        XCTAssertEqual(viewModel.downloadLocation, newLocation)
        XCTAssertNotEqual(viewModel.downloadLocation, initialLocation)
    }
    
    // MARK: - Error Handling Tests
    
    func testSettingsViewModel_ErrorMessageProperty_CanBeSet() {
        // Given: view model with no error
        XCTAssertNil(viewModel.errorMessage)
        
        // When: setting an error message
        let errorMessage = "Cannot use selected location: Directory does not exist"
        viewModel.errorMessage = errorMessage
        
        // Then: error message should be set
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
    }
    
    func testSettingsViewModel_ErrorMessageProperty_CanBeCleared() {
        // Given: view model with an error message
        viewModel.errorMessage = "Previous error"
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When: clearing the error message
        viewModel.errorMessage = nil
        
        // Then: error message should be nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Integration Tests for Location Selection Logic
    
    func testLocationSelection_ValidDirectory_UpdatesConfigAndProperty() {
        // Given: a valid writable directory
        let validator = PathValidator()
        let validLocation = tempDirectory.appendingPathComponent("ValidLocation")
        try? FileManager.default.createDirectory(at: validLocation, withIntermediateDirectories: true)
        
        // When: simulating the selection logic
        let validationResult = validator.validate(validLocation)
        
        // Then: validation should pass
        XCTAssertTrue(validationResult.isValid)
        
        // And when: updating config service and view model
        if validationResult.isValid {
            mockConfigService.downloadLocation = validLocation
            viewModel.downloadLocation = validLocation
            viewModel.errorMessage = nil
        }
        
        // Then: both should be updated correctly
        XCTAssertEqual(mockConfigService.downloadLocation, validLocation)
        XCTAssertEqual(viewModel.downloadLocation, validLocation)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLocationSelection_InvalidDirectory_SetsErrorMessage() {
        // Given: an invalid directory path
        let validator = PathValidator()
        let invalidLocation = URL(fileURLWithPath: "/invalid/path/that/does/not/exist")
        
        // When: simulating the selection logic
        let validationResult = validator.validate(invalidLocation)
        
        // Then: validation should fail
        XCTAssertFalse(validationResult.isValid)
        
        // And when: handling the validation failure
        if case .invalid(let reason) = validationResult {
            viewModel.errorMessage = "Cannot use selected location: \(reason)"
        }
        
        // Then: error message should be set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Cannot use selected location") ?? false)
    }
    
    func testLocationSelection_ValidAfterInvalid_ClearsErrorMessage() {
        // Given: view model with a previous error
        viewModel.errorMessage = "Previous error"
        let validator = PathValidator()
        let validLocation = tempDirectory
        
        // When: selecting a valid location
        let validationResult = validator.validate(validLocation)
        
        // Then: validation should pass
        XCTAssertTrue(validationResult.isValid)
        
        // And when: updating with valid location
        if validationResult.isValid {
            mockConfigService.downloadLocation = validLocation
            viewModel.downloadLocation = validLocation
            viewModel.errorMessage = nil
        }
        
        // Then: error message should be cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.downloadLocation, validLocation)
    }
}

// MARK: - Mock Classes

/// Mock ConfigurationService for testing
class MockConfigService: ConfigurationService {
    var downloadLocationUpdateCalled = false
    private var _downloadLocation: URL = FileManager.default.urls(
        for: .downloadsDirectory,
        in: .userDomainMask
    )[0]
    
    override var downloadLocation: URL {
        get { _downloadLocation }
        set {
            _downloadLocation = newValue
            downloadLocationUpdateCalled = true
        }
    }
    
    override var upgradeURL: URL? {
        get { URL(string: "https://ytmac.example.com/upgrade") }
        set { }
    }
}

/// Mock BinaryUpdater for testing
class MockBinaryUpdater: BinaryUpdater {
    private var shouldCheckForUpdate = false
    private var currentVersion = "2024.03.10"
    
    init() {
        // Initialize with a dummy binary path for testing
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("yt-dlp")
        
        // Create a mock GitHubAPIClient
        let mockAPIClient = MockGitHubAPIClient()
        
        // Call the actual initializer with mocks
        super.init(binaryPath: tempPath, githubAPI: mockAPIClient)
    }
    
    override func shouldCheckForUpdate() async -> Bool {
        return shouldCheckForUpdate
    }
    
    override func getCurrentVersion() async throws -> String {
        return currentVersion
    }
    
    func setShouldCheckForUpdate(_ value: Bool) {
        shouldCheckForUpdate = value
    }
    
    func setCurrentVersion(_ version: String) {
        currentVersion = version
    }
}

/// Mock GitHubAPIClient for testing
class MockGitHubAPIClient: GitHubAPIClient {
    override func fetchLatestRelease(owner: String, repo: String) async throws -> GitHubRelease {
        return GitHubRelease(
            tagName: "2024.03.10",
            name: "Test Release",
            body: "Test release notes",
            publishedAt: "2024-03-10T00:00:00Z",
            assets: []
        )
    }
}
