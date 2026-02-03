//
//  QuestionPoolProgressManaging.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuestionPoolProgressManaging {
    func getUsedIds(version: Int) -> Set<String>
    func markUsed(_ questionIds: [String], version: Int)
    func reset(version: Int)
    
    // Legacy method - deprecated in favor of intersection-based calculation
    func getProgressStats(total: Int, version: Int) -> (used: Int, remaining: Int)
    
    // New method with intersection-based calculation
    func getProgressStats(total: Int, currentQuestionIds: Set<String>, version: Int) -> (used: Int, remaining: Int)
    
    // Режимы изучения
    func isReviewMode(version: Int) -> Bool
    func setReviewMode(_ enabled: Bool, version: Int)
    
    // Legacy method - deprecated in favor of intersection-based calculation
    func isBankCompleted(total: Int, version: Int) -> Bool
    
    // New method with intersection-based calculation
    func isBankCompleted(currentQuestionIds: Set<String>, version: Int) -> Bool
}

