//
//  GitHubAPIClientTests.swift
//  YTMacTests
//
//  Tests for GitHubAPIClient functionality
//

import XCTest
@testable import YTMac

final class GitHubAPIClientTests: XCTestCase {
    
    // MARK: - Mock URLSession
    
    /// Mock URLSession for testing network requests without hitting real endpoints
    class MockURLSession: URLSession {
        var mockData: Data?
        var mockResponse: URLResponse?
        var mockError: Error?
        
        override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = mockError {
                throw error
            }
            
            guard let data = mockData, let response = mockResponse else {
                throw NSError(domain: "MockURLSession", code: -1, userInfo: nil)
            }
            
            return (data, response)
        }
    }
    
    // MARK: - Test Cases
    
    func testFetchLatestRelease_Success() async throws {
        // Given: Valid GitHub API response with macOS asset
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let jsonResponse = """
        {
            "tag_name": "2024.03.10",
            "body": "Bug fixes and improvements",
            "assets": [
                {
                    "name": "yt-dlp_macos",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_macos"
                },
                {
                    "name": "yt-dlp.exe",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp.exe"
                }
            ]
        }
        """
        
        mockSession.mockData = jsonResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When: Fetching latest release
        let updateInfo = try await client.fetchLatestRelease()
        
        // Then: Update info should be correctly parsed
        XCTAssertEqual(updateInfo.latestVersion, "2024.03.10")
        XCTAssertEqual(updateInfo.downloadURL.absoluteString, "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_macos")
        XCTAssertEqual(updateInfo.releaseNotes, "Bug fixes and improvements")
    }
    
    func testFetchLatestRelease_VersionWithVPrefix() async throws {
        // Given: Version tag with 'v' prefix
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let jsonResponse = """
        {
            "tag_name": "v2024.03.10",
            "body": "Release notes",
            "assets": [
                {
                    "name": "yt-dlp_macos",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/v2024.03.10/yt-dlp_macos"
                }
            ]
        }
        """
        
        mockSession.mockData = jsonResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When: Fetching release
        let updateInfo = try await client.fetchLatestRelease()
        
        // Then: 'v' prefix should be removed
        XCTAssertEqual(updateInfo.latestVersion, "2024.03.10")
    }
    
    func testFetchLatestRelease_DarwinAsset() async throws {
        // Given: Asset named with 'darwin' instead of 'macos'
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let jsonResponse = """
        {
            "tag_name": "2024.03.10",
            "body": "Release notes",
            "assets": [
                {
                    "name": "yt-dlp_darwin",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_darwin"
                }
            ]
        }
        """
        
        mockSession.mockData = jsonResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When: Fetching release
        let updateInfo = try await client.fetchLatestRelease()
        
        // Then: Darwin asset should be found
        XCTAssertTrue(updateInfo.downloadURL.absoluteString.contains("darwin"))
    }
    
    func testFetchLatestRelease_HTTPError() async throws {
        // Given: HTTP 404 response
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then: Should throw HTTP error
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected HTTPError to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .httpError(let statusCode, _):
                XCTAssertEqual(statusCode, 404)
            default:
                XCTFail("Expected httpError, got \(error)")
            }
        }
    }
    
    func testFetchLatestRelease_NetworkError() async throws {
        // Given: Network error
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        mockSession.mockError = networkError
        
        // When/Then: Should throw network error
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected networkError to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .networkError:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected networkError, got \(error)")
            }
        }
    }
    
    func testFetchLatestRelease_TimeoutError() async throws {
        // Given: Timeout error
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: nil
        )
        mockSession.mockError = timeoutError
        
        // When/Then: Should throw timeout error
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected timeoutError to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .timeoutError:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected timeoutError, got \(error)")
            }
        }
    }
    
    func testFetchLatestRelease_JSONParsingError() async throws {
        // Given: Invalid JSON response
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let invalidJSON = "{ invalid json }"
        mockSession.mockData = invalidJSON.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then: Should throw JSON parsing error
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected jsonParsingError to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .jsonParsingError:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected jsonParsingError, got \(error)")
            }
        }
    }
    
    func testFetchLatestRelease_NoMacOSAsset() async throws {
        // Given: Response with no macOS or darwin assets
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let jsonResponse = """
        {
            "tag_name": "2024.03.10",
            "body": "Release notes",
            "assets": [
                {
                    "name": "yt-dlp.exe",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp.exe"
                },
                {
                    "name": "yt-dlp_linux",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_linux"
                }
            ]
        }
        """
        
        mockSession.mockData = jsonResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then: Should throw no asset found error
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected noAssetFound error to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .noAssetFound:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected noAssetFound, got \(error)")
            }
        }
    }
    
    func testFetchLatestRelease_CaseInsensitiveAssetMatching() async throws {
        // Given: Asset with uppercase "MacOS" in name
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        let jsonResponse = """
        {
            "tag_name": "2024.03.10",
            "body": "Release notes",
            "assets": [
                {
                    "name": "yt-dlp_MacOS",
                    "browser_download_url": "https://github.com/yt-dlp/yt-dlp/releases/download/2024.03.10/yt-dlp_MacOS"
                }
            ]
        }
        """
        
        mockSession.mockData = jsonResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When: Fetching release
        let updateInfo = try await client.fetchLatestRelease()
        
        // Then: Asset should be found despite case difference
        XCTAssertTrue(updateInfo.downloadURL.absoluteString.contains("MacOS"))
    }
    
    func testFetchLatestRelease_RateLimitError() async throws {
        // Given: HTTP 429 (rate limit) response
        let mockSession = MockURLSession()
        let client = GitHubAPIClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When/Then: Should throw HTTP error with 429 status
        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("Expected HTTPError to be thrown")
        } catch let error as GitHubAPIClient.APIError {
            switch error {
            case .httpError(let statusCode, _):
                XCTAssertEqual(statusCode, 429)
            default:
                XCTFail("Expected httpError with 429, got \(error)")
            }
        }
    }
}
