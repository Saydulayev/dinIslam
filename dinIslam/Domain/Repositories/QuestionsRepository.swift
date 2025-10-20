//
//  QuestionsRepository.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

protocol QuestionsRepositoryProtocol {
    func loadQuestions(language: String) async throws -> [Question]
}

class QuestionsRepository: QuestionsRepositoryProtocol {
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func loadQuestions(language: String) async throws -> [Question] {
        guard let url = bundle.url(forResource: "questions", withExtension: "json") else {
            throw QuestionsError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let allQuestions = try JSONDecoder().decode([Question].self, from: data)
        
        let filteredQuestions = allQuestions.filter { $0.language == language }
        
        guard !filteredQuestions.isEmpty else {
            throw QuestionsError.emptyData
        }
        
        return filteredQuestions
    }
}

enum QuestionsError: LocalizedError {
    case fileNotFound
    case emptyData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return NSLocalizedString("error.fileNotFound", comment: "Questions file not found")
        case .emptyData:
            return NSLocalizedString("error.emptyData", comment: "No questions found")
        case .decodingError:
            return NSLocalizedString("error.decodingError", comment: "Failed to decode questions")
        }
    }
}
