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
    private let reviewModeKey = "QuestionPool.reviewMode"
    
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
        userDefaults.set(false, forKey: reviewModeKey)
    }
    
    // MARK: - Legacy Progress Methods (without intersection)
    
    func getProgressStats(total: Int, version: Int) -> (used: Int, remaining: Int) {
        let usedIds = getUsedIds(version: version)
        let usedCount = usedIds.count
        let remainingCount = max(0, total - usedCount)
        return (used: usedCount, remaining: remainingCount)
    }
    
    func isBankCompleted(total: Int, version: Int) -> Bool {
        let usedIds = getUsedIds(version: version)
        return usedIds.count >= total
    }
    
    // MARK: - New Progress Methods (with intersection)
    
    func getProgressStats(total: Int, currentQuestionIds: Set<String>, version: Int) -> (used: Int, remaining: Int) {
        let usedIds = getUsedIds(version: version)
        // Calculate intersection: only count usedIds that actually exist in current question bank
        let actuallyUsed = usedIds.intersection(currentQuestionIds)
        let usedCount = actuallyUsed.count
        let remainingCount = max(0, total - usedCount)
        return (used: usedCount, remaining: remainingCount)
    }
    
    func isBankCompleted(currentQuestionIds: Set<String>, version: Int) -> Bool {
        let usedIds = getUsedIds(version: version)
        // Calculate intersection: only count usedIds that actually exist in current question bank
        let actuallyUsed = usedIds.intersection(currentQuestionIds)
        return actuallyUsed.count >= currentQuestionIds.count
    }
    
    // MARK: - Review Mode
    
    func isReviewMode(version: Int) -> Bool {
        ensureVersion(version)
        return userDefaults.bool(forKey: reviewModeKey)
    }
    
    func setReviewMode(_ enabled: Bool, version: Int) {
        ensureVersion(version)
        userDefaults.set(enabled, forKey: reviewModeKey)
    }
    
    private func ensureVersion(_ currentVersion: Int) {
        let savedVersion = userDefaults.integer(forKey: versionKey)
        if savedVersion != currentVersion {
            reset(version: currentVersion)
        }
    }
}

