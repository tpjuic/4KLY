//
//  ProgressParserTests.swift
//  YTMacTests
//
//  Unit tests for ProgressParser utility class
//  Validates Requirements: 4.3
//

import XCTest
@testable import YTMac

final class ProgressParserTests: XCTestCase {
    
    var parser: ProgressParser!
    
    override func setUp() {
        super.setUp()
        parser = ProgressParser()
    }
    
    // MARK: - Standard Progress Parsing Tests
    
    func testParse_StandardProgressMessage_ReturnsCorrectProgress() {
        // Given
        let output = "[download]  12.3% of 45.67MiB at 1.23MiB/s ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result, "Should successfully parse standard progress message")
        XCTAssertEqual(result?.percentage, 0.123, accuracy: 0.0001,
                      "Percentage should be converted to 0.0-1.0 range")
        XCTAssertEqual(result?.totalBytes, 47_875_481, // 45.67 * 1024 * 1024
                      "Total bytes should be correctly converted from MiB")
        XCTAssertEqual(result?.downloadedBytes, Int64(Double(47_875_481) * 0.123), // 12.3% of total
                      "Downloaded bytes should be calculated from percentage")
        XCTAssertEqual(result?.speed, 1_289_748, // 1.23 * 1024 * 1024
                      "Speed should be correctly converted from MiB/s")
        XCTAssertEqual(result?.eta, 32.0,
                      "ETA should be converted to seconds")
    }
    
    func testParse_ProgressWithLargerETA_ReturnsCorrectETA() {
        // Given
        let output = "[download]  5.0% of 100.0MiB at 0.5MiB/s ETA 03:10"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.eta, 190.0, // 3 * 60 + 10
                      "ETA should correctly convert minutes and seconds")
    }
    
    func testParse_ProgressWithZeroETA_ReturnsZeroETA() {
        // Given
        let output = "[download]  99.9% of 10.0MiB at 5.0MiB/s ETA 00:00"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.eta, 0.0,
                      "ETA should handle zero values")
    }
    
    func testParse_ProgressWithWholePercentage_ParsesCorrectly() {
        // Given
        let output = "[download]  50% of 20.0MiB at 2.0MiB/s ETA 00:05"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.50, accuracy: 0.0001,
                      "Should handle percentage without decimal point")
    }
    
    func testParse_ProgressWithDecimalPercentage_ParsesCorrectly() {
        // Given
        let output = "[download]  33.333% of 30.0MiB at 1.5MiB/s ETA 00:13"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.33333, accuracy: 0.00001,
                      "Should handle multiple decimal places in percentage")
    }
    
    // MARK: - Completion Message Tests
    
    func testParse_CompletionMessage_Returns100Percent() {
        // Given
        let output = "[download] 100% of 45.67MiB in 00:35"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result, "Should successfully parse completion message")
        XCTAssertEqual(result?.percentage, 1.0,
                      "Completion should have 100% progress")
        XCTAssertEqual(result?.totalBytes, 47_875_481, // 45.67 * 1024 * 1024
                      "Total bytes should be correctly converted")
        XCTAssertEqual(result?.downloadedBytes, result?.totalBytes,
                      "Downloaded bytes should equal total bytes at completion")
        XCTAssertEqual(result?.speed, 0,
                      "Speed should be 0 at completion")
        XCTAssertEqual(result?.eta, 0,
                      "ETA should be 0 at completion")
    }
    
    func testParse_CompletionMessageWithDecimal_Returns100Percent() {
        // Given
        let output = "[download] 100.0% of 10.5MiB in 01:20"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 1.0,
                      "Should handle 100.0% completion format")
    }
    
    // MARK: - Unit Conversion Tests
    
    func testParse_BytesUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  10.0% of 1024B at 512B/s ETA 00:02"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 1024,
                      "Should correctly parse bytes unit")
        XCTAssertEqual(result?.speed, 512,
                      "Should correctly parse speed in bytes/s")
    }
    
    func testParse_KiBUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  25.0% of 100.0KiB at 10.0KiB/s ETA 00:07"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 102_400, // 100 * 1024
                      "Should correctly convert KiB to bytes")
        XCTAssertEqual(result?.speed, 10_240, // 10 * 1024
                      "Should correctly convert KiB/s to bytes/s")
    }
    
    func testParse_GiBUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  15.0% of 2.5GiB at 0.1GiB/s ETA 00:21"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 2_684_354_560, // 2.5 * 1024 * 1024 * 1024
                      "Should correctly convert GiB to bytes")
        XCTAssertEqual(result?.speed, 107_374_182, // 0.1 * 1024 * 1024 * 1024
                      "Should correctly convert GiB/s to bytes/s")
    }
    
    func testParse_DecimalKBUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  50.0% of 1000KB at 100KB/s ETA 00:05"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 1_000_000, // 1000 * 1000
                      "Should correctly convert decimal KB to bytes")
        XCTAssertEqual(result?.speed, 100_000, // 100 * 1000
                      "Should correctly convert decimal KB/s to bytes/s")
    }
    
    func testParse_DecimalMBUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  20.0% of 50.0MB at 5.0MB/s ETA 00:08"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 50_000_000, // 50 * 1000 * 1000
                      "Should correctly convert decimal MB to bytes")
        XCTAssertEqual(result?.speed, 5_000_000, // 5 * 1000 * 1000
                      "Should correctly convert decimal MB/s to bytes/s")
    }
    
    func testParse_DecimalGBUnit_ParsesCorrectly() {
        // Given
        let output = "[download]  10.0% of 5.0GB at 0.5GB/s ETA 00:09"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 5_000_000_000, // 5 * 1000 * 1000 * 1000
                      "Should correctly convert decimal GB to bytes")
        XCTAssertEqual(result?.speed, 500_000_000, // 0.5 * 1000 * 1000 * 1000
                      "Should correctly convert decimal GB/s to bytes/s")
    }
    
    // MARK: - Invalid Format Tests
    
    func testParse_InvalidFormat_ReturnsNil() {
        // Given
        let output = "This is not a valid progress message"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for invalid format")
    }
    
    func testParse_EmptyString_ReturnsNil() {
        // Given
        let output = ""
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for empty string")
    }
    
    func testParse_MissingPercentage_ReturnsNil() {
        // Given
        let output = "[download] of 45.67MiB at 1.23MiB/s ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil when percentage is missing")
    }
    
    func testParse_MissingTotalSize_ReturnsNil() {
        // Given
        let output = "[download]  12.3% of at 1.23MiB/s ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil when total size is missing")
    }
    
    func testParse_MissingSpeed_ReturnsNil() {
        // Given
        let output = "[download]  12.3% of 45.67MiB at ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil when speed is missing")
    }
    
    func testParse_MissingETA_ReturnsNil() {
        // Given
        let output = "[download]  12.3% of 45.67MiB at 1.23MiB/s"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil when ETA is missing")
    }
    
    func testParse_InvalidUnit_ReturnsNil() {
        // Given
        let output = "[download]  12.3% of 45.67XYZ at 1.23XYZ/s ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for unrecognized units")
    }
    
    func testParse_MalformedETA_ReturnsNil() {
        // Given
        let output = "[download]  12.3% of 45.67MiB at 1.23MiB/s ETA XX:YY"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for malformed ETA")
    }
    
    // MARK: - Edge Case Tests
    
    func testParse_VerySmallPercentage_ParsesCorrectly() {
        // Given
        let output = "[download]  0.1% of 1000.0MiB at 0.5MiB/s ETA 33:20"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.001, accuracy: 0.0001,
                      "Should handle very small percentages")
    }
    
    func testParse_VeryLargeFile_ParsesCorrectly() {
        // Given
        let output = "[download]  1.0% of 5000.0MiB at 10.0MiB/s ETA 08:20"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBytes, 5_242_880_000, // 5000 * 1024 * 1024
                      "Should handle large file sizes")
    }
    
    func testParse_VerySlowSpeed_ParsesCorrectly() {
        // Given
        let output = "[download]  10.0% of 10.0MiB at 0.01MiB/s ETA 15:00"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.speed, 10_485, // 0.01 * 1024 * 1024
                      "Should handle very slow speeds")
    }
    
    func testParse_ExtraWhitespace_ParsesCorrectly() {
        // Given - yt-dlp sometimes adds extra spaces
        let output = "[download]   50.0%  of  100.0MiB  at  5.0MiB/s  ETA  00:10"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result,
                       "Should handle extra whitespace in output")
    }
    
    func testParse_DestinationLine_ReturnsNil() {
        // Given - this is a different type of output line from yt-dlp
        let output = "[download] Destination: VideoTitle.mp4"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for destination lines")
    }
    
    func testParse_MergingLine_ReturnsNil() {
        // Given - this is output during file merging
        let output = "[ffmpeg] Merging formats into \"output.mp4\""
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNil(result,
                    "Should return nil for ffmpeg merge lines")
    }
    
    // MARK: - Real-World Output Tests
    
    func testParse_RealYouTubeProgress_ParsesCorrectly() {
        // Given - actual yt-dlp output format
        let output = "[download]  45.8% of 127.34MiB at 2.15MiB/s ETA 00:32"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.458, accuracy: 0.001)
        XCTAssertEqual(result?.speed, 2_254_438, accuracy: 1000)
    }
    
    func testParse_RealCompletionMessage_ParsesCorrectly() {
        // Given - actual yt-dlp completion format
        let output = "[download] 100% of 127.34MiB in 01:02"
        
        // When
        let result = parser.parse(from: output)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 1.0)
        XCTAssertEqual(result?.downloadedBytes, result?.totalBytes)
    }
}
