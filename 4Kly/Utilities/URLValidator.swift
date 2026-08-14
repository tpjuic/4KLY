//
//  URLValidator.swift
//  YTMac
//
//  Created by YTMac Developer
//

import Foundation

/// Validates URL input strings for video downloads
class URLValidator {
    
    /// Validates whether a URL input string is acceptable
    /// - Parameter input: The URL string to validate
    /// - Returns: ValidationResult indicating whether the input is valid
    func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid
        }
        
        return .valid
    }
}

/// Result of URL validation
enum ValidationResult {
    case valid
    case invalid
}
