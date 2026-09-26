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
    private let remoteService: RemoteQuestionsService
    private let useRemoteQuestions: Bool
    
    init(bundle: Bundle = .main, remoteService: RemoteQuestionsService = RemoteQuestionsService(), useRemoteQuestions: Bool = true) {
        self.bundle = bundle
        self.remoteService = remoteService
        self.useRemoteQuestions = useRemoteQuestions
    }
    
    func loadQuestions(language: String) async throws -> [Question] {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        
        if useRemoteQuestions {
            // Try to load from remote first
            let remoteQuestions = await remoteService.fetchQuestions(for: appLanguage)
            if !remoteQuestions.isEmpty {
                return remoteQuestions
            }
        }
        
        // Fallback to local questions
        return try loadLocalQuestions(language: language)
    }
    
    private func loadLocalQuestions(language: String) throws -> [Question] {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        return try QuestionsFile.loadBundled(for: appLanguage, bundle: bundle)
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
