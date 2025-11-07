//
//  Question.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

struct Question: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let answers: [Answer]
    let correctIndex: Int
    let category: String
    let difficulty: Difficulty
    
    enum CodingKeys: String, CodingKey {
        case id, text, answers, correctIndex, category, difficulty
    }
}

struct Answer: Codable, Identifiable, Equatable {
    let id: String
    let text: String
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var localizedName: String {
        switch self {
        case .easy:
            return NSLocalizedString("difficulty.easy", comment: "Easy difficulty")
        case .medium:
            return NSLocalizedString("difficulty.medium", comment: "Medium difficulty")
        case .hard:
            return NSLocalizedString("difficulty.hard", comment: "Hard difficulty")
        }
    }
}

enum QuizState: Equatable {
    case idle
    case active(ActiveState)
    case completed(CompletedState)
    case error(ErrorState)
}

enum ActiveState: Equatable {
    case loading
    case playing
    case mistakesReview
}

enum CompletedState: Equatable {
    case finished
    case mistakesFinished
}

enum ErrorState: Equatable {
    case networkError
    case dataError
    case unknownError
}

struct QuizResult: Equatable, Hashable {
    let totalQuestions: Int
    let correctAnswers: Int
    let percentage: Double
    let timeSpent: TimeInterval
    
    var isNewRecord: Bool {
        return percentage > 0.8 // 80% threshold for new record
    }
}
