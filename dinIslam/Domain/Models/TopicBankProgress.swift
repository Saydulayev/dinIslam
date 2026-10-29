//
//  TopicBankProgress.swift
//  dinIslam
//
//  Сколько вопросов темы в банке и сколько из них уже изучено.
//

import Foundation

struct TopicBankProgress: Equatable, Identifiable {
    let category: QuestionCategory
    let progress: BankProgress

    var id: QuestionCategory { category }

    var studiedFraction: Double {
        progress.total > 0 ? Double(progress.studied) / Double(progress.total) : 0
    }
}
