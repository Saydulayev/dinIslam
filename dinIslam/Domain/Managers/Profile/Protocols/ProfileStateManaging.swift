//
//  ProfileStateManaging.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol ProfileStateManaging: AnyObject {
    var syncState: ProfileManager.SyncState { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

