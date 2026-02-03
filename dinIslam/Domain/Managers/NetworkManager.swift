//
//  NetworkManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Network
import Combine
import OSLog

// MARK: - Network Error Types
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noInternetConnection
    case serverError(Int)
    case clientError(Int)
    case timeout
    case decodingError(Error)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noInternetConnection:
            return "No internet connection"
        case .serverError(let code):
            return "Server error: \(code)"
        case .clientError(let code):
            return "Client error: \(code)"
        case .timeout:
            return "Request timeout"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .timeout, .serverError:
            return true
        case .invalidURL, .clientError, .decodingError, .unknownError:
            return false
        }
    }
}

// MARK: - Network Response with Metadata
struct NetworkResponse<T: Codable> {
    let data: T
    let etag: String?
    let lastModified: Date?
    let statusCode: Int
    let notModified: Bool
    
    init(data: T, etag: String?, lastModified: Date?, statusCode: Int) {
        self.data = data
        self.etag = etag
        self.lastModified = lastModified
        self.statusCode = statusCode
        self.notModified = statusCode == 304
    }
}

// MARK: - Network Configuration
struct NetworkConfiguration {
    let timeout: TimeInterval
    let maxRetries: Int
    let retryDelay: TimeInterval
    let maxRetryDelay: TimeInterval
    
    static let `default` = NetworkConfiguration(
        timeout: 30.0,
        maxRetries: 3,
        retryDelay: 1.0,
        maxRetryDelay: 10.0
    )
}

// MARK: - Network Manager
class NetworkManager: ObservableObject {
    private let session: URLSession
    private let configuration: NetworkConfiguration
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    init(configuration: NetworkConfiguration = .default) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        
        self.session = URLSession(configuration: sessionConfig)
        
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        url: String,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        guard isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknownError(NSError(domain: "Invalid response", code: -1))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
                
            case 400...499:
                let error = NetworkError.clientError(httpResponse.statusCode)
                throw error
                
            case 500...599:
                let error = NetworkError.serverError(httpResponse.statusCode)
                if error.isRetryable && retryCount < configuration.maxRetries {
                    return try await retryRequest(url: url, responseType: responseType, retryCount: retryCount + 1)
                }
                throw error
                
            default:
                throw NetworkError.unknownError(NSError(domain: "Unknown status code", code: httpResponse.statusCode))
            }
            
        } catch let error as NetworkError {
            if error.isRetryable && retryCount < configuration.maxRetries {
                return try await retryRequest(url: url, responseType: responseType, retryCount: retryCount + 1)
            }
            throw error
        } catch {
            let networkError = NetworkError.unknownError(error)
            if networkError.isRetryable && retryCount < configuration.maxRetries {
                return try await retryRequest(url: url, responseType: responseType, retryCount: retryCount + 1)
            }
            throw networkError
        }
    }
    
    private func retryRequest<T: Codable>(
        url: URL,
        responseType: T.Type,
        retryCount: Int
    ) async throws -> T {
        let delay = min(
            self.configuration.retryDelay * pow(2.0, Double(retryCount - 1)),
            self.configuration.maxRetryDelay
        )
        
        AppLogger.network.info("Retrying request in \(delay) seconds (attempt \(retryCount + 1)/\(self.configuration.maxRetries))")
        
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await request(url: url.absoluteString, responseType: responseType, retryCount: retryCount)
    }
    
    // MARK: - Request with ETag Support
    func requestWithMetadata<T: Codable>(
        url: String,
        responseType: T.Type,
        cachedEtag: String? = nil,
        cachedData: T? = nil,
        retryCount: Int = 0
    ) async throws -> NetworkResponse<T> {
        guard isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        // Create request with conditional headers
        var request = URLRequest(url: requestURL)
        if let etag = cachedEtag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            AppLogger.network.info("Sending conditional request with ETag: \(etag)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknownError(NSError(domain: "Invalid response", code: -1))
            }
            
            // Extract ETag and Last-Modified from response headers
            let newEtag = httpResponse.value(forHTTPHeaderField: "ETag")
            let lastModifiedString = httpResponse.value(forHTTPHeaderField: "Last-Modified")
            let lastModified = lastModifiedString.flatMap { RFC1123DateFormatter.date(from: $0) }
            
            switch httpResponse.statusCode {
            case 304:
                // Not Modified
                AppLogger.network.info("Content not modified (304)")
                // For 304, we return a special response with empty data
                // The caller is responsible for using their cached data
                // We decode an empty array for the response type (works for array types)
                let emptyData = Data("[]".utf8)
                let emptyResponse = try? JSONDecoder().decode(T.self, from: emptyData)
                
                // If we can't decode empty data, use cached data if available
                if let decoded = emptyResponse {
                    return NetworkResponse(
                        data: decoded,
                        etag: newEtag ?? cachedEtag,
                        lastModified: lastModified,
                        statusCode: 304
                    )
                } else if let cachedData = cachedData {
                    return NetworkResponse(
                        data: cachedData,
                        etag: newEtag ?? cachedEtag,
                        lastModified: lastModified,
                        statusCode: 304
                    )
                } else {
                    throw NetworkError.unknownError(NSError(domain: "Cannot handle 304 response without cached data", code: 304))
                }
                
            case 200...299:
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                AppLogger.network.info("Content updated (200), new ETag: \(newEtag ?? "none")")
                return NetworkResponse(
                    data: decodedResponse,
                    etag: newEtag,
                    lastModified: lastModified,
                    statusCode: httpResponse.statusCode
                )
                
            case 400...499:
                let error = NetworkError.clientError(httpResponse.statusCode)
                throw error
                
            case 500...599:
                let error = NetworkError.serverError(httpResponse.statusCode)
                if error.isRetryable && retryCount < configuration.maxRetries {
                    return try await retryRequestWithMetadata(
                        url: url,
                        responseType: responseType,
                        cachedEtag: cachedEtag,
                        cachedData: cachedData,
                        retryCount: retryCount + 1
                    )
                }
                throw error
                
            default:
                throw NetworkError.unknownError(NSError(domain: "Unknown status code", code: httpResponse.statusCode))
            }
            
        } catch let error as NetworkError {
            if error.isRetryable && retryCount < configuration.maxRetries {
                return try await retryRequestWithMetadata(
                    url: url,
                    responseType: responseType,
                    cachedEtag: cachedEtag,
                    cachedData: cachedData,
                    retryCount: retryCount + 1
                )
            }
            throw error
        } catch {
            let networkError = NetworkError.unknownError(error)
            if networkError.isRetryable && retryCount < configuration.maxRetries {
                return try await retryRequestWithMetadata(
                    url: url,
                    responseType: responseType,
                    cachedEtag: cachedEtag,
                    cachedData: cachedData,
                    retryCount: retryCount + 1
                )
            }
            throw networkError
        }
    }
    
    private func retryRequestWithMetadata<T: Codable>(
        url: String,
        responseType: T.Type,
        cachedEtag: String?,
        cachedData: T?,
        retryCount: Int
    ) async throws -> NetworkResponse<T> {
        let delay = min(
            self.configuration.retryDelay * pow(2.0, Double(retryCount - 1)),
            self.configuration.maxRetryDelay
        )
        
        AppLogger.network.info("Retrying metadata request in \(delay) seconds (attempt \(retryCount + 1)/\(self.configuration.maxRetries))")
        
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await requestWithMetadata(
            url: url,
            responseType: responseType,
            cachedEtag: cachedEtag,
            cachedData: cachedData,
            retryCount: retryCount
        )
    }
}

// MARK: - RFC 1123 Date Formatter
private enum RFC1123DateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()
    
    static func date(from string: String) -> Date? {
        return formatter.date(from: string)
    }
}
