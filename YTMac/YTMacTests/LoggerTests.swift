//
//  LoggerTests.swift
//  YTMacTests
//
//  Created by YTMac Developer
//  Tests for Logger singleton
//

import XCTest
@testable import YTMac

final class LoggerTests: XCTestCase {
    
    func testLoggerSingletonExists() {
        // Test that Logger.shared is accessible
        let logger = Logger.shared
        XCTAssertNotNil(logger, "Logger singleton should be accessible")
    }
    
    func testLoggerSingletonIsSameInstance() {
        // Test that multiple calls to Logger.shared return the same instance
        let logger1 = Logger.shared
        let logger2 = Logger.shared
        XCTAssertTrue(logger1 === logger2, "Logger.shared should return the same instance")
    }
    
    func testLogLevelsExist() {
        // Test that all required log levels exist
        let debugLevel = Logger.LogLevel.debug
        let infoLevel = Logger.LogLevel.info
        let warningLevel = Logger.LogLevel.warning
        let errorLevel = Logger.LogLevel.error
        
        XCTAssertEqual(debugLevel.rawValue, "DEBUG")
        XCTAssertEqual(infoLevel.rawValue, "INFO")
        XCTAssertEqual(warningLevel.rawValue, "WARNING")
        XCTAssertEqual(errorLevel.rawValue, "ERROR")
    }
    
    func testLogMethodDoesNotCrash() {
        // Test that logging doesn't crash
        let logger = Logger.shared
        
        logger.log("Test message", level: .info)
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        
        // Wait briefly for async queue to process
        let expectation = self.expectation(description: "Log queue processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLogFileIsCreated() throws {
        // Test that log file exists after initialization
        let logger = Logger.shared
        logger.info("Test log file creation")
        
        // Wait for async write
        Thread.sleep(forTimeInterval: 0.2)
        
        let logsDir = try FileSystemManager.shared.ensureLogsDirectory()
        let logFileURL = logsDir.appendingPathComponent("ytmac.log")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFileURL.path),
                      "Log file should exist at ~/Library/Logs/YTMac/ytmac.log")
    }
    
    func testLogMessageFormat() throws {
        // Test that log messages are written with correct format
        let logger = Logger.shared
        let testMessage = "Test format message \(UUID().uuidString)"
        
        logger.info(testMessage)
        
        // Wait for async write
        Thread.sleep(forTimeInterval: 0.2)
        
        let logsDir = try FileSystemManager.shared.ensureLogsDirectory()
        let logFileURL = logsDir.appendingPathComponent("ytmac.log")
        
        let logContents = try String(contentsOf: logFileURL, encoding: .utf8)
        
        // Check that our test message appears in the log
        XCTAssertTrue(logContents.contains(testMessage),
                      "Log file should contain the test message")
        
        // Check for format elements (timestamp, level, file, function)
        XCTAssertTrue(logContents.contains("[INFO]"),
                      "Log should contain [INFO] level marker")
        XCTAssertTrue(logContents.contains("LoggerTests.swift"),
                      "Log should contain source file name")
    }
    
    func testMultipleLogLevels() throws {
        // Test that different log levels are correctly written
        let logger = Logger.shared
        let uuid = UUID().uuidString
        
        logger.debug("Debug \(uuid)")
        logger.info("Info \(uuid)")
        logger.warning("Warning \(uuid)")
        logger.error("Error \(uuid)")
        
        // Wait for async writes
        Thread.sleep(forTimeInterval: 0.3)
        
        let logsDir = try FileSystemManager.shared.ensureLogsDirectory()
        let logFileURL = logsDir.appendingPathComponent("ytmac.log")
        let logContents = try String(contentsOf: logFileURL, encoding: .utf8)
        
        XCTAssertTrue(logContents.contains("[DEBUG]") && logContents.contains("Debug \(uuid)"),
                      "Log should contain DEBUG level message")
        XCTAssertTrue(logContents.contains("[INFO]") && logContents.contains("Info \(uuid)"),
                      "Log should contain INFO level message")
        XCTAssertTrue(logContents.contains("[WARNING]") && logContents.contains("Warning \(uuid)"),
                      "Log should contain WARNING level message")
        XCTAssertTrue(logContents.contains("[ERROR]") && logContents.contains("Error \(uuid)"),
                      "Log should contain ERROR level message")
    }
    
    func testLogContextInformation() throws {
        // Test that context information (file, function, line) is captured
        let logger = Logger.shared
        let testMessage = "Context test \(UUID().uuidString)"
        
        logger.info(testMessage) // Line where log is called
        
        Thread.sleep(forTimeInterval: 0.2)
        
        let logsDir = try FileSystemManager.shared.ensureLogsDirectory()
        let logFileURL = logsDir.appendingPathComponent("ytmac.log")
        let logContents = try String(contentsOf: logFileURL, encoding: .utf8)
        
        // Find the line with our test message
        let lines = logContents.components(separatedBy: "\n")
        let matchingLine = lines.first { $0.contains(testMessage) }
        
        XCTAssertNotNil(matchingLine, "Should find log line with test message")
        
        // Check for context elements
        if let line = matchingLine {
            XCTAssertTrue(line.contains("LoggerTests.swift:"),
                          "Log should contain file name with line number")
            XCTAssertTrue(line.contains("testLogContextInformation()"),
                          "Log should contain function name")
        }
    }
}
