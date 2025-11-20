//
//  QuestionsPreloading.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuestionsPreloading {
    func preloadQuestions(for languages: [String]) async
}

