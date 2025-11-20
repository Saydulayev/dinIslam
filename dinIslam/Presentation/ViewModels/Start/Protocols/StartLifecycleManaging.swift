//
//  StartLifecycleManaging.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol StartLifecycleManaging {
    func onAppear(
        onLanguageCodeUpdate: (String) -> Void,
        onProfileSync: @escaping () async -> Void
    )
    
    func onDisappear(cancelTask: () -> Void)
    
    func onLanguageChange(
        onLanguageCodeUpdate: (String) -> Void
    )
}

