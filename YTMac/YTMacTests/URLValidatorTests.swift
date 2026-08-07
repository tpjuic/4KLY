//
//  URLValidatorTests.swift
//  YTMacTests
//
//  Created by YTMac Developer
//

import XCTest
@testable import YTMac

final class URLValidatorTests: XCTestCase {
    
    var validator: URLValidator!
    
    override func setUp() {
        super.setUp()
        validator = URLValidator()
    }
    
    // MARK: - Valid Input Tests
    
    func testValidate_NonEmptyString_ReturnsValid() {
        // Given
        let input = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "Non-empty URL string should be valid")
    }
    
    func testValidate_StringWithContent_ReturnsValid() {
        // Given
        let input = "some content"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "Any non-empty string with content should be valid")
    }
    
    func testValidate_StringWithLeadingWhitespace_ReturnsValid() {
        // Given
        let input = "   https://example.com"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "String with leading whitespace but content should be valid after trimming")
    }
    
    func testValidate_StringWithTrailingWhitespace_ReturnsValid() {
        // Given
        let input = "https://example.com   "
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "String with trailing whitespace but content should be valid after trimming")
    }
    
    func testValidate_StringWithSurroundingWhitespace_ReturnsValid() {
        // Given
        let input = "   https://example.com   "
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "String with surrounding whitespace but content should be valid after trimming")
    }
    
    // MARK: - Invalid Input Tests
    
    func testValidate_EmptyString_ReturnsInvalid() {
        // Given
        let input = ""
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .invalid,
                      "Empty string should be invalid")
    }
    
    func testValidate_OnlySpaces_ReturnsInvalid() {
        // Given
        let input = "   "
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .invalid,
                      "String with only spaces should be invalid")
    }
    
    func testValidate_OnlyTabs_ReturnsInvalid() {
        // Given
        let input = "\t\t\t"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .invalid,
                      "String with only tabs should be invalid")
    }
    
    func testValidate_OnlyNewlines_ReturnsInvalid() {
        // Given
        let input = "\n\n\n"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .invalid,
                      "String with only newlines should be invalid")
    }
    
    func testValidate_MixedWhitespace_ReturnsInvalid() {
        // Given
        let input = "  \t\n  \t  "
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .invalid,
                      "String with mixed whitespace characters should be invalid")
    }
    
    // MARK: - Edge Case Tests
    
    func testValidate_SingleCharacter_ReturnsValid() {
        // Given
        let input = "a"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "Single character string should be valid")
    }
    
    func testValidate_UnicodeCharacters_ReturnsValid() {
        // Given
        let input = "你好世界"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "String with unicode characters should be valid")
    }
    
    func testValidate_SpecialCharacters_ReturnsValid() {
        // Given
        let input = "!@#$%^&*()"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "String with special characters should be valid")
    }
    
    func testValidate_URLWithQueryParameters_ReturnsValid() {
        // Given
        let input = "https://example.com/path?param1=value1&param2=value2"
        
        // When
        let result = validator.validate(input)
        
        // Then
        XCTAssertEqual(result, .valid,
                      "URL with query parameters should be valid")
    }
}
