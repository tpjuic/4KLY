//
//  QualityGate.swift
//  YTMac
//
//  Protocol and supporting types for quality validation strategy.
//  Implements Requirements 2.4, 2.5, 10.2, 12.1, 12.2
//

import Foundation

// MARK: - QualityGate Protocol

/// Protocol defining quality validation strategy for video downloads.
/// Enables pluggable validation for free vs premium tiers.
///
/// Validates: Requirements 12.1, 12.2
protocol QualityGate {
    /// Validates whether a given video quality is allowed.
    ///
    /// - Parameter quality: The video quality to validate
    /// - Returns: Validation result indicating allowed or blocked with upgrade prompt
    ///
    /// Validates: Requirements 2.4, 2.5
    func validateQuality(_ quality: VideoQuality) async -> QualityValidationResult
}

// MARK: - QualityValidationResult

/// Result of quality validation operation.
///
/// Validates: Requirements 2.4, 2.5, 10.2
enum QualityValidationResult {
    /// Quality is allowed and download can proceed
    case allowed
    
    /// Quality is blocked and requires upgrade
    ///
    /// - Parameters:
    ///   - reason: Technical reason for blocking (for logging)
    ///   - upgradePrompt: User-facing prompt information
    case blocked(reason: String, upgradePrompt: UpgradePromptInfo)
}

// MARK: - FreeQualityGate Implementation

/// Free version implementation of QualityGate that restricts downloads to ≤720p.
/// Blocks higher resolutions with upgrade prompt.
///
/// Validates: Requirements 2.4, 2.6, 2.7, 10.2, 12.1
actor FreeQualityGate: QualityGate {
    private let configService: ConfigurationService
    
    /// Initialize with configuration service dependency
    ///
    /// - Parameter configService: Service providing upgrade URL configuration
    init(configService: ConfigurationService) {
        self.configService = configService
    }
    
    /// Validates whether a given video quality is allowed in the free version.
    /// Allows resolutions ≤720p, blocks resolutions >720p with upgrade prompt.
    ///
    /// - Parameter quality: The video quality to validate
    /// - Returns: `.allowed` for standard quality (≤720p), `.blocked` with upgrade prompt for high quality (>720p)
    ///
    /// Validates: Requirements 2.4, 2.6, 2.7, 10.2
    func validateQuality(_ quality: VideoQuality) async -> QualityValidationResult {
        // Check if resolution exceeds free tier limit (720p)
        guard quality.resolution <= 720 else {
            // Fetch upgrade URL from configuration service
            let upgradeURL = await configService.getUpgradeURL()
            
            // Create upgrade prompt with configured URL
            let prompt = UpgradePromptInfo(
                message: "Upgrade to Premium for 4K downloads. Your purchase supports independent development.",
                upgradeURL: upgradeURL
            )
            
            return .blocked(
                reason: "Resolution \(quality.resolution)p exceeds free tier limit of 720p",
                upgradePrompt: prompt
            )
        }
        
        // Resolution is within free tier limits
        return .allowed
    }
}
