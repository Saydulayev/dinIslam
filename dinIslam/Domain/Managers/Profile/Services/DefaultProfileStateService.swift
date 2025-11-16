//
//  DefaultProfileStateService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultProfileStateService: ProfileStateManaging {
    var syncState: ProfileManager.SyncState = .idle
    var isLoading: Bool = false
    var errorMessage: String?
}

