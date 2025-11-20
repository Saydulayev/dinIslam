//
//  ProfileAuthHandling.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import AuthenticationServices
import Foundation

protocol ProfileAuthHandling {
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest)
    
    func handleSignInResult(
        _ result: Result<ASAuthorization, Error>,
        onSuccess: @escaping (ASAuthorizationAppleIDCredential) async -> Void,
        onFailure: @escaping (String) -> Void
    )
}

