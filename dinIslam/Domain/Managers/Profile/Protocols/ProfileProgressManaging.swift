//
//  ProfileProgressManaging.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol ProfileProgressManaging {
    func rebuildProgressFromLocalStats(profile: inout UserProfile)
    
    func syncProgressToLocalStats(profile: UserProfile)
}

