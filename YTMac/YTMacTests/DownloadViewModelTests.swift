//
//  DownloadViewModelTests.swift
//  YTMacTests
//
//  Unit tests for DownloadViewModel submitDownload() method
//  Validates: Requirements 1.2, 1.3, 1.4, 2.3, 5.1
//

import XCTest
@testable import YTMac

@MainActor
final class DownloadViewModelTests: XCTestCase {
    
    var viewModel: DownloadViewModel!
    var mockDownloadManager: MockDownloadManager!
    var mockQualityGate: MockQualityGate!
    var mockProcessExecutor: MockProcessExecutor!
    var mockHistoryStore: MockDownloadHistoryStore!
    var mockConfigService: MockConfigurationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock dependencies
        mockProcessExecutor = MockProcessExecutor()
        mockQualityGate = MockQualityGate()
        mockHistoryStore = MockDownloadHistoryStore()
        mockConfigService = MockConfigurationService()
        
        mockDownloadManager = MockDownloadManager(
            processExecutor: mockProcessExecutor,
            qualityGate: mockQualityGate,
            historyStore: mockHistoryStore,
            configService: mockConfigService
        )
        
        viewModel = DownloadViewModel(downloadManager: mockDownloadManager)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockDownloadManager = nil
        mockQualityGate = nil
        mockProcessExecutor = nil
        mockHistoryStore = nil
        mockConfigService = nil
        try await super.tearDown()
    }
    
    // MARK: - URL Validation Tests
    
    func testSubmitDownload_EmptyURL_SetsErrorMessage() async {
        // Given: empty URL input
        viewModel.urlInput = ""
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: error message should be set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid URL")
    }
    
    func testSubmitDownload_WhitespaceOnlyURL_SetsErrorMessage() async {
        // Given: whitespace-only URL input
        viewModel.urlInput = "   \n\t   "
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: error message should be set
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid URL")
    }
    
    // MARK: - Single URL Submission Tests
    
    func testSubmitDownload_SingleValidURL_CallsDownloadManagerSubmitDownload() async {
        // Given: valid single URL and standard quality
        viewModel.urlInput = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        viewModel.selectedQuality = .standard720p
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should call submitDownload (not submitBatch)
        let submitCallCount = await mockDownloadManager.getSubmitDownloadCallCount()
        let batchCallCount = await mockDownloadManager.getSubmitBatchCallCount()
        let lastURL = await mockDownloadManager.getLastSubmittedURL()
        let lastQuality = await mockDownloadManager.getLastSubmittedQuality()
        
        XCTAssertEqual(submitCallCount, 1)
        XCTAssertEqual(batchCallCount, 0)
        XCTAssertEqual(lastURL, "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(lastQuality, .standard720p)
    }
    
    func testSubmitDownload_SingleURL_ClearsInputOnSuccess() async {
        // Given: valid single URL
        viewModel.urlInput = "https://www.youtube.com/watch?v=test"
        viewModel.selectedQuality = .standard480p
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: input should be cleared
        XCTAssertEqual(viewModel.urlInput, "")
    }
    
    // MARK: - Multi-URL Submission Tests
    
    func testSubmitDownload_MultipleURLsNewlineSeparated_CallsSubmitBatch() async {
        // Given: multiple URLs separated by newlines
        viewModel.urlInput = """
        https://www.youtube.com/watch?v=url1
        https://www.youtube.com/watch?v=url2
        https://www.youtube.com/watch?v=url3
        """
        viewModel.selectedQuality = .standard720p
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should call submitBatch (not submitDownload)
        let submitCallCount = await mockDownloadManager.getSubmitDownloadCallCount()
        let batchCallCount = await mockDownloadManager.getSubmitBatchCallCount()
        let batchURLs = await mockDownloadManager.getLastSubmittedBatchURLs()
        
        XCTAssertEqual(submitCallCount, 0)
        XCTAssertEqual(batchCallCount, 1)
        XCTAssertEqual(batchURLs?.count, 3)
        XCTAssertEqual(batchURLs?[0], "https://www.youtube.com/watch?v=url1")
        XCTAssertEqual(batchURLs?[1], "https://www.youtube.com/watch?v=url2")
        XCTAssertEqual(batchURLs?[2], "https://www.youtube.com/watch?v=url3")
    }
    
    func testSubmitDownload_MultipleURLsCommaSeparated_CallsSubmitBatch() async {
        // Given: multiple URLs separated by commas
        viewModel.urlInput = "https://example.com/video1, https://example.com/video2"
        viewModel.selectedQuality = .standard360p
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should call submitBatch with 2 URLs
        let batchCallCount = await mockDownloadManager.getSubmitBatchCallCount()
        let batchURLs = await mockDownloadManager.getLastSubmittedBatchURLs()
        
        XCTAssertEqual(batchCallCount, 1)
        XCTAssertEqual(batchURLs?.count, 2)
    }
    
    func testSubmitDownload_MultipleBatch_ClearsInputOnSuccess() async {
        // Given: multiple valid URLs
        viewModel.urlInput = "https://url1.com\nhttps://url2.com"
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: input should be cleared
        XCTAssertEqual(viewModel.urlInput, "")
    }
    
    // MARK: - Quality Gate Error Handling Tests
    
    func testSubmitDownload_QualityBlocked_ShowsUpgradePrompt() async {
        // Given: high quality that will be blocked
        viewModel.urlInput = "https://www.youtube.com/watch?v=test"
        viewModel.selectedQuality = .high1080p
        await mockQualityGate.setShouldAllow(false)
        await mockQualityGate.setUpgradePrompt(UpgradePromptInfo(
            message: "Try our Premium version to download in high quality",
            upgradeURL: URL(string: "https://ytmac.example.com/upgrade")
        ))
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should show upgrade prompt
        XCTAssertTrue(viewModel.showUpgradePrompt)
        XCTAssertNotNil(viewModel.upgradePromptInfo)
        XCTAssertEqual(viewModel.upgradePromptInfo?.message, "Try our Premium version to download in high quality")
        XCTAssertEqual(viewModel.upgradePromptInfo?.upgradeURL?.absoluteString, "https://ytmac.example.com/upgrade")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSubmitDownload_QualityBlocked_DoesNotClearInput() async {
        // Given: high quality that will be blocked
        let originalInput = "https://www.youtube.com/watch?v=test"
        viewModel.urlInput = originalInput
        viewModel.selectedQuality = .high4k
        await mockQualityGate.setShouldAllow(false)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: input should NOT be cleared (user might want to retry with different quality)
        XCTAssertEqual(viewModel.urlInput, originalInput)
    }
    
    // MARK: - General Error Handling Tests
    
    func testSubmitDownload_DownloadManagerError_SetsErrorMessage() async {
        // Given: download manager that will throw an error
        viewModel.urlInput = "https://www.youtube.com/watch?v=test"
        viewModel.selectedQuality = .standard720p
        await mockQualityGate.setShouldAllow(true)
        await mockDownloadManager.setShouldThrowError(true)
        await mockDownloadManager.setErrorToThrow(DownloadError.networkFailure)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should set error message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Network error") ?? false)
        XCTAssertFalse(viewModel.showUpgradePrompt)
    }
    
    // MARK: - Edge Cases
    
    func testSubmitDownload_URLWithLeadingTrailingWhitespace_TrimsAndProcesses() async {
        // Given: URL with whitespace
        viewModel.urlInput = "  https://www.youtube.com/watch?v=test  \n"
        viewModel.selectedQuality = .standard720p
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should process with trimmed URL
        let lastURL = await mockDownloadManager.getLastSubmittedURL()
        XCTAssertEqual(lastURL, "https://www.youtube.com/watch?v=test")
    }
    
    func testSubmitDownload_MixedNewlineAndComma_ParsesAllURLs() async {
        // Given: URLs separated by mix of newlines and commas
        viewModel.urlInput = "https://url1.com,https://url2.com\nhttps://url3.com"
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting download
        await viewModel.submitDownload()
        
        // Then: should parse all 3 URLs
        let batchURLs = await mockDownloadManager.getLastSubmittedBatchURLs()
        XCTAssertEqual(batchURLs?.count, 3)
    }
    
    func testSubmitDownload_ClearsErrorMessageBeforeValidation() async {
        // Given: existing error message
        viewModel.errorMessage = "Previous error"
        viewModel.urlInput = "https://www.youtube.com/watch?v=test"
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting new download
        await viewModel.submitDownload()
        
        // Then: error message should be cleared
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSubmitDownload_ClearsUpgradePromptBeforeValidation() async {
        // Given: existing upgrade prompt
        viewModel.showUpgradePrompt = true
        viewModel.upgradePromptInfo = UpgradePromptInfo(message: "Old prompt", upgradeURL: nil)
        viewModel.urlInput = "https://www.youtube.com/watch?v=test"
        await mockQualityGate.setShouldAllow(true)
        
        // When: submitting new download
        await viewModel.submitDownload()
        
        // Then: upgrade prompt should be cleared
        XCTAssertFalse(viewModel.showUpgradePrompt)
        XCTAssertNil(viewModel.upgradePromptInfo)
    }
}

// MARK: - Mock Classes

/// Mock DownloadManager for testing
actor MockDownloadManager {
    private var submitDownloadCallCount = 0
    private var submitBatchCallCount = 0
    private var lastSubmittedURL: String?
    private var lastSubmittedQuality: VideoQuality?
    private var lastSubmittedBatchURLs: [String]?
    private var shouldThrowError = false
    private var errorToThrow: Error?
    
    private let processExecutor: ProcessExecutor
    private let qualityGate: QualityGate
    private let historyStore: DownloadHistoryStore
    private let configService: ConfigurationService
    
    private var updateContinuation: AsyncStream<DownloadJob>.Continuation?
    private let updateStream: AsyncStream<DownloadJob>
    
    init(
        processExecutor: ProcessExecutor,
        qualityGate: QualityGate,
        historyStore: DownloadHistoryStore,
        configService: ConfigurationService
    ) {
        self.processExecutor = processExecutor
        self.qualityGate = qualityGate
        self.historyStore = historyStore
        self.configService = configService
        
        var continuation: AsyncStream<DownloadJob>.Continuation?
        self.updateStream = AsyncStream { cont in
            continuation = cont
        }
        self.updateContinuation = continuation
    }
    
    func submitDownload(url: String, quality: VideoQuality) async throws -> UUID {
        submitDownloadCallCount += 1
        lastSubmittedURL = url
        lastSubmittedQuality = quality
        
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        // Validate quality through gate
        let validationResult = await qualityGate.validateQuality(quality)
        if case .blocked(_, let prompt) = validationResult {
            throw QualityGateError.qualityBlocked(prompt: prompt)
        }
        
        return UUID()
    }
    
    func submitBatch(urls: [String], quality: VideoQuality) async -> [UUID] {
        submitBatchCallCount += 1
        lastSubmittedBatchURLs = urls
        lastSubmittedQuality = quality
        
        return urls.map { _ in UUID() }
    }
    
    func getUpdateStream() -> AsyncStream<DownloadJob> {
        return updateStream
    }
    
    // Accessors for test assertions
    func getSubmitDownloadCallCount() -> Int { submitDownloadCallCount }
    func getSubmitBatchCallCount() -> Int { submitBatchCallCount }
    func getLastSubmittedURL() -> String? { lastSubmittedURL }
    func getLastSubmittedQuality() -> VideoQuality? { lastSubmittedQuality }
    func getLastSubmittedBatchURLs() -> [String]? { lastSubmittedBatchURLs }
    
    func setShouldThrowError(_ value: Bool) { shouldThrowError = value }
    func setErrorToThrow(_ error: Error?) { errorToThrow = error }
}

/// Mock QualityGate for testing
actor MockQualityGate: QualityGate {
    private var shouldAllow = true
    private var upgradePrompt: UpgradePromptInfo?
    
    func validateQuality(_ quality: VideoQuality) async -> QualityValidationResult {
        if shouldAllow {
            return .allowed
        } else {
            let prompt = upgradePrompt ?? UpgradePromptInfo(
                message: "Try our Premium version to download in high quality",
                upgradeURL: URL(string: "https://ytmac.example.com/upgrade")
            )
            return .blocked(reason: "Quality blocked", upgradePrompt: prompt)
        }
    }
    
    func setShouldAllow(_ value: Bool) { shouldAllow = value }
    func setUpgradePrompt(_ prompt: UpgradePromptInfo?) { upgradePrompt = prompt }
}

/// Mock ProcessExecutor for testing
actor MockProcessExecutor {
    func execute(
        url: String,
        quality: VideoQuality,
        outputPath: URL,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws -> ProcessResult {
        return ProcessResult(exitCode: 0, outputPath: outputPath, error: nil)
    }
}

/// Mock DownloadHistoryStore for testing
@MainActor
class MockDownloadHistoryStore: DownloadHistoryStore {
    var saveDownloadCalled = false
    var savedJob: DownloadJob?
    var deleteAllCalled = false
    var shouldThrowError = false
    
    // Create a mock ModelContext for initialization
    init() {
        // We need to create a minimal ModelContext
        // For testing purposes, we'll use a temporary in-memory container
        let schema = Schema([DownloadHistoryItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = ModelContext(container)
        
        super.init(modelContext: context)
    }
    
    override func saveDownload(_ job: DownloadJob) throws {
        saveDownloadCalled = true
        savedJob = job
        // Don't actually save to avoid SwiftData operations
    }
    
    override func deleteAll() throws {
        deleteAllCalled = true
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock delete error"])
        }
        // Don't actually delete to avoid SwiftData operations
    }
}

/// Mock ConfigurationService for testing
class MockConfigurationService: ConfigurationService {
    override var downloadLocation: URL {
        get { URL(fileURLWithPath: "/tmp/downloads") }
        set { }
    }
}
