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
}
