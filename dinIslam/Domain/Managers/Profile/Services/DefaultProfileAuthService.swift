//
//  DefaultProfileAuthService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import AuthenticationServices
import Foundation

final class DefaultProfileAuthService: ProfileAuthHandling {
    private let authService: ProfileAuthService
    
    init(authService: ProfileAuthService) {
        self.authService = authService
    }
    
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        authService.prepareSignInRequest(request)
    }
    
    func handleSignInResult(
        _ result: Result<ASAuthorization, Error>,
        onSuccess: @escaping (ASAuthorizationAppleIDCredential) async -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        authService.handleSignInResult(
            result,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }
}

