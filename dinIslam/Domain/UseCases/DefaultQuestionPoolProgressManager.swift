//
//  DefaultQuestionPoolProgressManager.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

struct DefaultQuestionPoolProgressManager: QuestionPoolProgressManaging {
    private let userDefaults: UserDefaults
    private let versionKey = "QuestionPool.version"
    private let usedIdsKey = "QuestionPool.usedIds"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func getUsedIds(version: Int) -> Set<String> {
        ensureVersion(version)
        let array = userDefaults.array(forKey: usedIdsKey) as? [String] ?? []
        return Set(array)
    }
    
    func markUsed(_ questionIds: [String], version: Int) {
        ensureVersion(version)
        var set = getUsedIds(version: version)
        for id in questionIds {
            set.insert(id)
        }
        userDefaults.set(Array(set), forKey: usedIdsKey)
    }
    
    func reset(version: Int) {
        userDefaults.set(version, forKey: versionKey)
        userDefaults.set([], forKey: usedIdsKey)
    }
    
    func getProgressStats(total: Int, version: Int) -> (used: Int, remaining: Int) {
        let usedIds = getUsedIds(version: version)
        let usedCount = usedIds.count
        let remainingCount = max(0, total - usedCount)
        return (used: usedCount, remaining: remainingCount)
    }
    
    private func ensureVersion(_ currentVersion: Int) {
        let savedVersion = userDefaults.integer(forKey: versionKey)
        if savedVersion != currentVersion {
            reset(version: currentVersion)
        }
    }
}

