# Utilities

This directory contains utility classes and helpers for 4Kly.

## FileSystemManager

Manages file system operations for 4Kly application directories.

### Features

- **ensureAppSupportDirectory()**: Returns `~/Library/Application Support/4Kly`, creating it with intermediate directories if needed
- **ensureLogsDirectory()**: Returns `~/Library/Logs/4Kly`, creating it with intermediate directories if needed

### Usage

```swift
let manager = FileSystemManager.shared

// Get Application Support directory for storing yt-dlp binary and app data
do {
    let appSupportURL = try manager.ensureAppSupportDirectory()
    print("App support: \(appSupportURL.path)")
    // Use this for: yt-dlp binary, configuration files, cached data
} catch {
    print("Error: \(error)")
}

// Get Logs directory for storing application logs
do {
    let logsURL = try manager.ensureLogsDirectory()
    print("Logs: \(logsURL.path)")
    // Use this for: error logs, debug logs, operation logs
} catch {
    print("Error: \(error)")
}
```

### Implementation Notes

- Uses singleton pattern (`FileSystemManager.shared`)
- Creates directories with `withIntermediateDirectories: true` for robustness
- Throws `FileSystemError` on failure
- Directories are created only if they don't already exist (idempotent)
- All operations use standard macOS directory locations via `FileManager`

### Requirements Satisfied

- **Requirement 3.1**: Provides application support directory for yt-dlp binary storage
- **Requirement 11.6**: Provides logs directory for error logging

### Testing

Run the standalone test script:

```bash
swift test_filesystem_manager.swift
```

Or use the manual test function (add to app initialization):

```swift
testFileSystemManager()  // Prints test results to console
```

## Logger

Thread-safe singleton logger for application-wide logging with file and console output.

### Features

- **Thread-safe**: Implemented as Swift actor for concurrent access
- **Multiple log levels**: debug, info, warning, error
- **Dual output**: Writes to file and console (console only in DEBUG builds)
- **Automatic context**: Captures file, function, and line number
- **Formatted timestamps**: ISO-style timestamps with milliseconds
- **Log file location**: `~/Library/Logs/4Kly/ytmac.log`

### Usage

```swift
// Simple logging
await Logger.shared.info("Application started")
await Logger.shared.debug("Debug information")
await Logger.shared.warning("Something might be wrong")
await Logger.shared.error("An error occurred")

// Context is automatically captured (file, line, function)
await Logger.shared.info("This will show the exact code location")

// Use in async functions
func performOperation() async {
    await Logger.shared.info("Operation started")
    // ... operation logic
    await Logger.shared.info("Operation completed")
}

// Use from sync context with Task
func syncFunction() {
    Task {
        await Logger.shared.info("Logging from sync context")
    }
}

// Get log file location
let logURL = await Logger.shared.getLogFileURL()
print("Logs at: \(logURL.path)")

// Clear logs (useful for testing or cleanup)
try await Logger.shared.clearLogs()
```

### Log Format

```
[YYYY-MM-DD HH:mm:ss.SSS] [LEVEL] [File:Line:Function] Message
```

Example:
```
[2024-03-15 14:23:45.123] [INFO] [DownloadManager.swift:45:submitDownload(url:quality:)] Starting download
```

### Implementation Notes

- **Actor-based**: Thread-safe concurrent access using Swift actor
- **Singleton pattern**: `Logger.shared`
- **Automatic directory creation**: Uses `FileSystemManager` to ensure log directory exists
- **File handle management**: Opens file once and appends to it
- **DEBUG conditional**: Console output only in debug builds (`#if DEBUG`)
- **Graceful fallback**: If log file creation fails, continues with console-only logging

### Requirements Satisfied

- **Requirement 10.5**: Logs upgrade prompt displays for analytics
- **Requirement 11.6**: Logs all errors to local file for debugging

### Testing

Run the XCTest suite:

```bash
swift test --filter LoggerTests
```

Or use the standalone test script:

```swift
await testLogger()  // Prints test results and last 5 log entries
```
