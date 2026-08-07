//
//  FreeQualityGateTests.swift
//  YTMacTests
//
//  Tests for FreeQualityGate actor implementation.
//  Validates Requirements 2.4, 2.6, 2.7, 10.2, 12.1
//

import XCTest
@testable import YTMac

final class FreeQualityGateTests: XCTestCase {
    
    var configService: ConfigurationService!
    var qualityGate: FreeQualityGate!
    
    override func setUp() async throws {
        try await super.setUp()
        configService = ConfigurationService()
        qualityGate = FreeQualityGate(configService: configService)
    }
    
    override func tearDown() async throws {
        qualityGate = nil
        configService = nil
        try await super.tearDown()
    }
    
    // MARK: - Standard Quality Tests (≤720p) - Should Allow
    
    func testAudioOnly_IsAllowed() async throws {
        // Given
        let quality = VideoQuality.audio_only
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTAssert(true, "Audio-only quality should be allowed")
        case .blocked:
            XCTFail("Audio-only quality should not be blocked")
        }
    }
    
    func testStandard360p_IsAllowed() async throws {
        // Given
        let quality = VideoQuality.standard360p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTAssert(true, "360p quality should be allowed")
        case .blocked:
            XCTFail("360p quality should not be blocked")
        }
    }
    
    func testStandard480p_IsAllowed() async throws {
        // Given
        let quality = VideoQuality.standard480p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTAssert(true, "480p quality should be allowed")
        case .blocked:
            XCTFail("480p quality should not be blocked")
        }
    }
    
    func testStandard720p_IsAllowed() async throws {
        // Given - boundary case
        let quality = VideoQuality.standard720p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTAssert(true, "720p quality (boundary) should be allowed")
        case .blocked:
            XCTFail("720p quality (boundary) should not be blocked")
        }
    }
    
    // MARK: - High Quality Tests (>720p) - Should Block
    
    func testHigh1080p_IsBlocked() async throws {
        // Given
        let quality = VideoQuality.high1080p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTFail("1080p quality should be blocked")
        case .blocked(let reason, let upgradePrompt):
            XCTAssertTrue(reason.contains("1080"), "Reason should mention resolution")
            XCTAssertTrue(reason.contains("720p"), "Reason should mention free tier limit")
            XCTAssertEqual(upgradePrompt.message, "Try our Premium version to download in high quality")
        }
    }
    
    func testHigh1440p_IsBlocked() async throws {
        // Given
        let quality = VideoQuality.high1440p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTFail("1440p quality should be blocked")
        case .blocked(let reason, let upgradePrompt):
            XCTAssertTrue(reason.contains("1440"), "Reason should mention resolution")
            XCTAssertTrue(reason.contains("720p"), "Reason should mention free tier limit")
            XCTAssertEqual(upgradePrompt.message, "Try our Premium version to download in high quality")
        }
    }
    
    func testHigh4K_IsBlocked() async throws {
        // Given
        let quality = VideoQuality.high4k
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTFail("4K quality should be blocked")
        case .blocked(let reason, let upgradePrompt):
            XCTAssertTrue(reason.contains("2160"), "Reason should mention resolution")
            XCTAssertTrue(reason.contains("720p"), "Reason should mention free tier limit")
            XCTAssertEqual(upgradePrompt.message, "Try our Premium version to download in high quality")
        }
    }
    
    // MARK: - Upgrade URL Configuration Tests
    
    func testUpgradePrompt_WithConfiguredURL() async throws {
        // Given
        let upgradeURL = URL(string: "https://ytmac.example.com/premium")!
        configService.upgradeURL = upgradeURL
        let quality = VideoQuality.high1080p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTFail("1080p should be blocked")
        case .blocked(_, let upgradePrompt):
            XCTAssertEqual(upgradePrompt.upgradeURL, upgradeURL, "Should include configured upgrade URL")
        }
    }
    
    func testUpgradePrompt_WithoutConfiguredURL() async throws {
        // Given
        configService.upgradeURL = nil
        let quality = VideoQuality.high1080p
        
        // When
        let result = await qualityGate.validateQuality(quality)
        
        // Then
        switch result {
        case .allowed:
            XCTFail("1080p should be blocked")
        case .blocked(_, let upgradePrompt):
            XCTAssertNil(upgradePrompt.upgradeURL, "Should be nil when not configured")
            XCTAssertEqual(upgradePrompt.message, "Try our Premium version to download in high quality")
        }
    }
    
    // MARK: - Boundary Tests
    
    func testAllStandardQualities_AreAllowed() async throws {
        // Given
        let standardQualities: [VideoQuality] = [
            .audio_only,
            .standard360p,
            .standard480p,
            .standard720p
        ]
        
        // When/Then
        for quality in standardQualities {
            let result = await qualityGate.validateQuality(quality)
            switch result {
            case .allowed:
                XCTAssert(true, "\(quality.displayName) should be allowed")
            case .blocked:
                XCTFail("\(quality.displayName) should not be blocked")
            }
        }
    }
    
    func testAllHighQualities_AreBlocked() async throws {
        // Given
        let highQualities: [VideoQuality] = [
            .high1080p,
            .high1440p,
            .high4k
        ]
        
        // When/Then
        for quality in highQualities {
            let result = await qualityGate.validateQuality(quality)
            switch result {
            case .allowed:
                XCTFail("\(quality.displayName) should be blocked")
            case .blocked:
                XCTAssert(true, "\(quality.displayName) should be blocked")
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentValidations_AreThreadSafe() async throws {
        // Given
        let qualities = VideoQuality.allCases
        
        // When - Execute concurrent validations
        await withTaskGroup(of: Void.self) { group in
            for quality in qualities {
                group.addTask {
                    _ = await self.qualityGate.validateQuality(quality)
                }
            }
        }
        
        // Then - No crashes or race conditions should occur
        XCTAssert(true, "Concurrent validations completed without crashes")
    }
}
