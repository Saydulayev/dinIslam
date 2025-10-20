//
//  QuestionPoolProgress.swift
//  dinIslam
//
//  Created by Assistant on 20.10.25.
//

import Foundation

struct QuestionPoolProgress {
    private let defaults = UserDefaults.standard
    private let versionKey = "QuestionPool.version"
    private let usedIdsKey = "QuestionPool.usedIds"
    private let currentVersion: Int
    
    init(version: Int) {
        self.currentVersion = version
        ensureVersion()
    }
    
    private func ensureVersion() {
        let savedVersion = defaults.integer(forKey: versionKey)
        if savedVersion != currentVersion {
            reset(for: currentVersion)
        }
    }
    
    var usedIds: Set<String> {
        let array = defaults.array(forKey: usedIdsKey) as? [String] ?? []
        return Set(array)
    }
    
    func reset(for newVersion: Int) {
        defaults.set(newVersion, forKey: versionKey)
        defaults.set([], forKey: usedIdsKey)
    }
    
    func markUsed(_ ids: [String]) {
        var set = usedIds
        for id in ids { set.insert(id) }
        defaults.set(Array(set), forKey: usedIdsKey)
    }
}


