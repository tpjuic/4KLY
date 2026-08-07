//
//  ErrorMessageTransformerTests.swift
//  YTMacTests
//
//  Unit tests for ErrorMessageTransformer
//  Validates Requirements: 11.2, 11.3, 11.5
//

import XCTest
@testable import YTMac

final class ErrorMessageTransformerTests: XCTestCase {
    
    var transformer: ErrorMessageTransformer!
    
    override func setUp() {
        super.setUp()
        transformer = ErrorMessageTransformer()
    }
    
    override func tearDown() {
        transformer = nil
        super.tearDown()
    }
    
    // MARK: - Unsupported URL Tests (Requirement 11.2)
    
    func testTransform_UnsupportedURL_ReturnsUserFriendlyMessage() {
        // Given
        let stderr = "ERROR: Unsupported URL: http://example.com/video"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "This site is not supported for downloading.",
                      "Should transform unsupported URL error to user-friendly message")
        XCTAssertFalse(result.contains("ERROR:"),
                      "Should not contain raw ERROR prefix")
        XCTAssertFalse(result.contains("Unsupported URL"),
                      "Should not contain raw error text")
    }
    
    // MARK: - Network Error Tests (Requirement 11.3)
    
    func testTransform_UnableToDownloadWebpage_ReturnsNetworkErrorMessage() {
        // Given
        let stderr = "ERROR: Unable to download webpage: HTTP Error 500"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Network error. Please check your internet connection.",
                      "Should transform network error to user-friendly message")
        XCTAssertFalse(result.contains("HTTP Error"),
                      "Should not contain raw HTTP error details")
    }
    
    // MARK: - Video Unavailable Tests (Requirement 11.2)
    
    func testTransform_VideoUnavailable_ReturnsVideoUnavailableMessage() {
        // Given
        let stderr = "ERROR: Video unavailable"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "This video is unavailable (it may be private, deleted, or restricted).",
                      "Should transform video unavailable error to user-friendly message")
        XCTAssertFalse(result.contains("ERROR:"),
                      "Should not contain raw ERROR prefix")
    }
    
    // MARK: - HTTP Error Tests (Requirement 11.5)
    
    func testTransform_HTTP403_ReturnsAccessDeniedMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 403: Forbidden"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Access denied. This video may be geo-restricted or require authentication.",
                      "Should transform HTTP 403 error to user-friendly message")
        XCTAssertFalse(result.contains("403"),
                      "Should not contain HTTP status code")
        XCTAssertFalse(result.contains("Forbidden"),
                      "Should not contain raw HTTP status text")
    }
    
    func testTransform_HTTP404_ReturnsNotFoundMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 404: Not Found"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Video not found. The URL may be incorrect or the video was removed.",
                      "Should transform HTTP 404 error to user-friendly message")
        XCTAssertFalse(result.contains("404"),
                      "Should not contain HTTP status code")
    }
    
    func testTransform_HTTP429_ReturnsTooManyRequestsMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 429: Too Many Requests"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Too many requests. Please wait a moment and try again.",
                      "Should transform HTTP 429 error to user-friendly message")
        XCTAssertFalse(result.contains("429"),
                      "Should not contain HTTP status code")
    }
    
    func testTransform_HTTP500_ReturnsServerErrorMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 500: Internal Server Error"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Server error. The video site is experiencing issues. Please try again later.",
                      "Should transform HTTP 500 error to user-friendly message")
        XCTAssertFalse(result.contains("500"),
                      "Should not contain HTTP status code")
    }
    
    func testTransform_HTTP503_ReturnsServiceUnavailableMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 503: Service Unavailable"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Service temporarily unavailable. Please try again later.",
                      "Should transform HTTP 503 error to user-friendly message")
        XCTAssertFalse(result.contains("503"),
                      "Should not contain HTTP status code")
    }
    
    func testTransform_GenericHTTPError_ReturnsGenericNetworkMessage() {
        // Given
        let stderr = "ERROR: HTTP Error 418: I'm a teapot"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Network error occurred. Please try again.",
                      "Should transform unknown HTTP error to generic network message")
        XCTAssertFalse(result.contains("418"),
                      "Should not contain HTTP status code")
        XCTAssertFalse(result.contains("teapot"),
                      "Should not contain raw HTTP status text")
    }
    
    // MARK: - Disk Space Tests
    
    func testTransform_DiskSpaceError_ReturnsDiskSpaceMessage() {
        // Given
        let stderr = "ERROR: No space left on device"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Insufficient disk space. Please free up space and try again.",
                      "Should transform disk space error to user-friendly message")
        XCTAssertFalse(result.contains("No space"),
                      "Should not contain raw error text")
        XCTAssertFalse(result.contains("device"),
                      "Should not contain technical terminology")
    }
    
    // MARK: - Timeout Tests
    
    func testTransform_TimeoutError_ReturnsTimeoutMessage() {
        // Given
        let stderr = "ERROR: Connection timed out"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Connection timed out. Please check your internet connection and try again.",
                      "Should transform timeout error to user-friendly message")
        XCTAssertFalse(result.contains("ERROR:"),
                      "Should not contain raw ERROR prefix")
    }
    
    // MARK: - SSL Error Tests
    
    func testTransform_SSLError_ReturnsSecureConnectionMessage() {
        // Given
        let stderr = "ERROR: SSL certificate verify failed"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Secure connection error. Please check your internet connection.",
                      "Should transform SSL error to user-friendly message")
        XCTAssertFalse(result.contains("SSL"),
                      "Should not contain technical SSL terminology")
        XCTAssertFalse(result.contains("certificate"),
                      "Should not contain technical certificate terminology")
    }
    
    // MARK: - Premium Content Tests
    
    func testTransform_PremiumContent_ReturnsPremiumContentMessage() {
        // Given
        let stderr = "ERROR: This video requires payment"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "This content requires a subscription or payment on the source site.",
                      "Should transform premium content error to user-friendly message")
        XCTAssertFalse(result.contains("requires payment"),
                      "Should not contain raw error text")
    }
    
    // MARK: - Geo-restriction Tests
    
    func testTransform_GeoRestriction_ReturnsGeoRestrictionMessage() {
        // Given
        let stderr = "ERROR: This video is not available in your country"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "This video is not available in your region.",
                      "Should transform geo-restriction error to user-friendly message")
        XCTAssertFalse(result.contains("country"),
                      "Should use 'region' instead of 'country'")
    }
    
    // MARK: - Age Restriction Tests
    
    func testTransform_AgeRestriction_ReturnsAgeRestrictionMessage() {
        // Given
        let stderr = "ERROR: This video is age restricted"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "This video is age-restricted and cannot be downloaded.",
                      "Should transform age restriction error to user-friendly message")
        XCTAssertFalse(result.contains("age restricted"),
                      "Should use hyphenated 'age-restricted'")
    }
    
    // MARK: - Live Stream Tests
    
    func testTransform_LiveStream_ReturnsLiveStreamMessage() {
        // Given
        let stderr = "ERROR: Cannot download live stream"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Live streams cannot be downloaded while they are ongoing.",
                      "Should transform live stream error to user-friendly message")
        XCTAssertFalse(result.contains("Cannot download"),
                      "Should not contain raw error text")
    }
    
    // MARK: - Generic Fallback Tests (Requirement 11.5)
    
    func testTransform_UnknownError_ReturnsGenericMessage() {
        // Given
        let stderr = "ERROR: Something went wrong with ffmpeg"
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "Download failed. Please verify the URL and try again.",
                      "Should transform unknown error to generic user-friendly message")
        XCTAssertFalse(result.contains("ffmpeg"),
                      "Should not contain technical tool names")
        XCTAssertFalse(result.contains("ERROR:"),
                      "Should not contain raw ERROR prefix")
    }
    
    func testTransform_EmptyStderr_ReturnsUnknownErrorMessage() {
        // Given
        let stderr = ""
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "An unknown error occurred.",
                      "Should return generic message for empty stderr")
    }
    
    func testTransform_WhitespaceOnlyStderr_ReturnsUnknownErrorMessage() {
        // Given
        let stderr = "   \n  \t  "
        
        // When
        let result = transformer.transform(ytdlpStderr: stderr)
        
        // Then
        XCTAssertEqual(result, "An unknown error occurred.",
                      "Should return generic message for whitespace-only stderr")
    }
    
    // MARK: - No Raw Details Tests (Requirement 11.5)
    
    func testTransform_MultipleErrors_NoRawDetailsInOutput() {
        // Given
        let technicalErrors = [
            "ERROR: Unsupported URL: http://badsite.com/video",
            "ERROR: Unable to download webpage: Connection refused",
            "ERROR: HTTP Error 403: Forbidden by robots.txt",
            "ERROR: ffmpeg not found in PATH",
            "ERROR: No space left on device at /tmp/ytdlp"
        ]
        
        // When & Then
        for stderr in technicalErrors {
            let result = transformer.transform(ytdlpStderr: stderr)
            
            // Should not contain raw error prefixes or technical paths
            XCTAssertFalse(result.contains("ERROR:"),
                          "Result should not contain ERROR: prefix for input: \(stderr)")
            XCTAssertFalse(result.contains("/tmp"),
                          "Result should not contain technical paths for input: \(stderr)")
            XCTAssertFalse(result.contains("/usr"),
                          "Result should not contain technical paths for input: \(stderr)")
            XCTAssertFalse(result.contains("PATH"),
                          "Result should not contain environment variables for input: \(stderr)")
            XCTAssertFalse(result.contains("robots.txt"),
                          "Result should not contain technical file names for input: \(stderr)")
        }
    }
}
