//
//  DefaultQuestionsPreloadingService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultQuestionsPreloadingService: QuestionsPreloading {
    private let enhancedQuizUseCase: EnhancedQuizUseCaseProtocol
    
    init(enhancedQuizUseCase: EnhancedQuizUseCaseProtocol) {
        self.enhancedQuizUseCase = enhancedQuizUseCase
    }
    
    func preloadQuestions(for languages: [String]) async {
        await enhancedQuizUseCase.preloadQuestions(for: languages)
    }
}

