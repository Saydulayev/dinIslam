//
//  DefaultProfileProgressService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultProfileProgressService: ProfileProgressManaging {
    private let progressBuilder: ProfileProgressBuilder
    
    init(progressBuilder: ProfileProgressBuilder) {
        self.progressBuilder = progressBuilder
    }
    
    func rebuildProgressFromLocalStats(profile: inout UserProfile) {
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
    }
    
    func syncProgressToLocalStats(profile: UserProfile) {
        progressBuilder.syncProgressToLocalStats(profile: profile)
    }
}

