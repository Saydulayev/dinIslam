//
//  ProfileAuthService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import AuthenticationServices
import CryptoKit
import Foundation

final class ProfileAuthService {
    private var currentNonce: String?
    
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleSignInResult(
        _ result: Result<ASAuthorization, Error>,
        onSuccess: @escaping (ASAuthorizationAppleIDCredential) async -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                onFailure(NSLocalizedString("profile.signin.invalidCredential", comment: "Invalid credential"))
                return
            }
            Task {
                await onSuccess(credential)
            }
        case .failure(let error):
            let friendlyMessage = userFriendlyErrorMessage(from: error)
            onFailure(friendlyMessage)
        }
    }
    
    // MARK: - Private Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("cancel") {
            return NSLocalizedString("profile.signin.cancelled", comment: "Sign in cancelled")
        }
        
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return NSLocalizedString("profile.signin.network", comment: "Network error")
        }
        
        return NSLocalizedString("profile.signin.error", comment: "Sign in error")
    }
}

