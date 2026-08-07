//
//  URLParserTests.swift
//  YTMacTests
//
//  Created by YTMac Developer
//

import XCTest
@testable import YTMac

final class URLParserTests: XCTestCase {
    
    var parser: URLParser!
    
    override func setUp() {
        super.setUp()
        parser = URLParser()
    }
    
    // MARK: - Single URL Tests
    
    func testParse_SingleURL_ReturnsArrayWithOneURL() {
        // Given
        let input = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 1,
                      "Single URL should return array with one element")
        XCTAssertEqual(result.first, input,
                      "Parsed URL should match input")
    }
    
    func testParse_SingleURLWithWhitespace_ReturnsTrimmedURL() {
        // Given
        let input = "  https://example.com  "
        let expected = "https://example.com"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 1,
                      "Should return array with one element")
        XCTAssertEqual(result.first, expected,
                      "Whitespace should be trimmed")
    }
    
    // MARK: - Newline Separator Tests
    
    func testParse_TwoURLsSeparatedByNewline_ReturnsTwoURLs() {
        // Given
        let input = "https://example.com/video1\nhttps://example.com/video2"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 2,
                      "Two URLs separated by newline should return array with two elements")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
    }
    
    func testParse_MultipleURLsSeparatedByNewlines_ReturnsAllURLs() {
        // Given
        let input = """
        https://example.com/video1
        https://example.com/video2
        https://example.com/video3
        https://example.com/video4
        """
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 4,
                      "Four URLs should be parsed")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
        XCTAssertEqual(result[3], "https://example.com/video4")
    }
    
    // MARK: - Comma Separator Tests
    
    func testParse_TwoURLsSeparatedByComma_ReturnsTwoURLs() {
        // Given
        let input = "https://example.com/video1,https://example.com/video2"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 2,
                      "Two URLs separated by comma should return array with two elements")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
    }
    
    func testParse_MultipleURLsSeparatedByCommas_ReturnsAllURLs() {
        // Given
        let input = "https://example.com/video1,https://example.com/video2,https://example.com/video3"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "Three URLs should be parsed")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    func testParse_CommaWithSpaces_TrimsWhitespace() {
        // Given
        let input = "https://example.com/video1, https://example.com/video2 , https://example.com/video3"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "Three URLs should be parsed")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    // MARK: - Mixed Separator Tests
    
    func testParse_MixedNewlinesAndCommas_ReturnsAllURLs() {
        // Given
        let input = """
        https://example.com/video1,https://example.com/video2
        https://example.com/video3,https://example.com/video4
        """
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 4,
                      "Four URLs with mixed separators should be parsed")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
        XCTAssertEqual(result[3], "https://example.com/video4")
    }
    
    // MARK: - Empty String Filtering Tests
    
    func testParse_EmptyString_ReturnsEmptyArray() {
        // Given
        let input = ""
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertTrue(result.isEmpty,
                     "Empty string should return empty array")
    }
    
    func testParse_OnlyWhitespace_ReturnsEmptyArray() {
        // Given
        let input = "   \t\n   "
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertTrue(result.isEmpty,
                     "Only whitespace should return empty array")
    }
    
    func testParse_OnlyCommas_ReturnsEmptyArray() {
        // Given
        let input = ",,,"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertTrue(result.isEmpty,
                     "Only commas should return empty array")
    }
    
    func testParse_OnlyNewlines_ReturnsEmptyArray() {
        // Given
        let input = "\n\n\n"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertTrue(result.isEmpty,
                     "Only newlines should return empty array")
    }
    
    func testParse_EmptyLinesBetweenURLs_FiltersOutEmptyLines() {
        // Given
        let input = """
        https://example.com/video1
        
        https://example.com/video2
        
        
        https://example.com/video3
        """
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "Empty lines should be filtered out")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    func testParse_EmptyCommasBetweenURLs_FiltersOutEmptyEntries() {
        // Given
        let input = "https://example.com/video1,,https://example.com/video2,,,https://example.com/video3"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "Empty comma entries should be filtered out")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    func testParse_TrailingComma_FiltersOutEmptyEntry() {
        // Given
        let input = "https://example.com/video1,https://example.com/video2,"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 2,
                      "Trailing comma should not add empty entry")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
    }
    
    func testParse_LeadingComma_FiltersOutEmptyEntry() {
        // Given
        let input = ",https://example.com/video1,https://example.com/video2"
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 2,
                      "Leading comma should not add empty entry")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
    }
    
    // MARK: - Edge Case Tests
    
    func testParse_URLsWithWhitespaceLines_TrimsAndFilters() {
        // Given
        let input = """
        https://example.com/video1
           
        https://example.com/video2
        \t
        https://example.com/video3
        """
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "Whitespace-only lines should be filtered out")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    func testParse_URLsWithVariousWhitespace_TrimsAll() {
        // Given
        let input = "  https://example.com/video1  ,\t\thttps://example.com/video2\t\t,   https://example.com/video3   "
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 3,
                      "All URLs should be trimmed")
        XCTAssertEqual(result[0], "https://example.com/video1")
        XCTAssertEqual(result[1], "https://example.com/video2")
        XCTAssertEqual(result[2], "https://example.com/video3")
    }
    
    func testParse_ComplexRealWorldInput_ParsesCorrectly() {
        // Given
        let input = """
        https://www.youtube.com/watch?v=dQw4w9WgXcQ
        https://www.youtube.com/watch?v=jNQXAC9IVRw, https://vimeo.com/123456789
        
        https://dailymotion.com/video/x8abc123
        
        
        https://www.twitch.tv/videos/1234567890,
        """
        
        // When
        let result = parser.parse(input)
        
        // Then
        XCTAssertEqual(result.count, 5,
                      "Complex real-world input should be parsed correctly")
        XCTAssertEqual(result[0], "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(result[1], "https://www.youtube.com/watch?v=jNQXAC9IVRw")
        XCTAssertEqual(result[2], "https://vimeo.com/123456789")
        XCTAssertEqual(result[3], "https://dailymotion.com/video/x8abc123")
        XCTAssertEqual(result[4], "https://www.twitch.tv/videos/1234567890")
    }
}
