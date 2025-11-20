//
//  ProfileErrorHandler.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import CloudKit
import Foundation

final class ProfileErrorHandler {
    static func userFriendlyErrorMessage(from error: Error) -> String {
        // Log the original error for debugging
        AppLogger.error("CloudKit sync error", error: error, category: AppLogger.data)
        
        // Get error description in lowercase for pattern matching
        let errorDescription = error.localizedDescription.lowercased()
        
        // Check for "oplock" errors first (most common conflict error)
        if errorDescription.contains("oplock") {
            AppLogger.info("Detected oplock error, returning conflict message", category: AppLogger.data)
            return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
        }
        
        // Check for CKError first
        if let ckError = error as? CKError {
            switch ckError.code {
            case .serverRecordChanged, .requestRateLimited:
                return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
            case .networkUnavailable, .networkFailure:
                return NSLocalizedString("profile.sync.error.network", comment: "Network error")
            case .quotaExceeded:
                return NSLocalizedString("profile.sync.error.quota", comment: "Quota exceeded error")
            case .notAuthenticated:
                return NSLocalizedString("profile.sync.error.auth", comment: "Authentication error")
            case .permissionFailure:
                return NSLocalizedString("profile.sync.error.permission", comment: "Permission error")
            default:
                break
            }
        }
        
        // Check for NSError with CloudKit domain
        if let nsError = error as NSError? {
            if nsError.domain == "CKErrorDomain" || nsError.domain.contains("CloudKit") {
                // This is a CloudKit error
                if errorDescription.contains("oplock") {
                    return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
                }
            }
        }
        
        // Check error description for other patterns
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return NSLocalizedString("profile.sync.error.network", comment: "Network error")
        }
        if errorDescription.contains("quota") || errorDescription.contains("limit") {
            return NSLocalizedString("profile.sync.error.quota", comment: "Quota exceeded error")
        }
        if errorDescription.contains("permission") || errorDescription.contains("unauthorized") {
            return NSLocalizedString("profile.sync.error.permission", comment: "Permission error")
        }
        if errorDescription.contains("not authenticated") || errorDescription.contains("authentication") {
            return NSLocalizedString("profile.sync.error.auth", comment: "Authentication error")
        }
        
        // Generic error message
        return NSLocalizedString("profile.sync.error.generic", comment: "Generic sync error")
    }
}

