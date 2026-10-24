//
//  DefaultQuestionsPreloadingService.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

final class DefaultQuestionsPreloadingService: QuestionsPreloading {
    private let questionsRepository: EnhancedQuestionsRepositoryProtocol
    
    init(questionsRepository: EnhancedQuestionsRepositoryProtocol) {
        self.questionsRepository = questionsRepository
    }
    
    func preloadQuestions(for languages: [String]) async {
        await questionsRepository.preloadQuestions(for: languages)
    }
}

