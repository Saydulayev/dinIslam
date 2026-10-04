//
//  ProfileErrorHandler.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
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
            return "profile.sync.error.conflict".localized
        }
        
        // Check for CKError first
        if let ckError = error as? CKError {
            switch ckError.code {
            case .serverRecordChanged, .requestRateLimited:
                return "profile.sync.error.conflict".localized
            case .networkUnavailable, .networkFailure:
                return "profile.sync.error.network".localized
            case .quotaExceeded:
                return "profile.sync.error.quota".localized
            case .notAuthenticated:
                return "profile.sync.error.auth".localized
            case .permissionFailure:
                return "profile.sync.error.permission".localized
            default:
                break
            }
        }
        
        // Check for NSError with CloudKit domain
        if let nsError = error as NSError? {
            if nsError.domain == "CKErrorDomain" || nsError.domain.contains("CloudKit") {
                // This is a CloudKit error
                if errorDescription.contains("oplock") {
                    return "profile.sync.error.conflict".localized
                }
            }
        }
        
        // Check error description for other patterns
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return "profile.sync.error.network".localized
        }
        if errorDescription.contains("quota") || errorDescription.contains("limit") {
            return "profile.sync.error.quota".localized
        }
        if errorDescription.contains("permission") || errorDescription.contains("unauthorized") {
            return "profile.sync.error.permission".localized
        }
        if errorDescription.contains("not authenticated") || errorDescription.contains("authentication") {
            return "profile.sync.error.auth".localized
        }
        
        // Generic error message
        return "profile.sync.error.generic".localized
    }
}

