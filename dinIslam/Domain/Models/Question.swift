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

    /// Последний ответ ссылается на остальные («Всё перечисленное», «Оба») и при перемешивании остаётся последним.
    /// Определяется по тексту ответа, поэтому файлы вопросов не нужно размечать
    var isLastAnswerFixed: Bool {
        answers.last?.refersToOtherAnswers ?? false
    }

    /// Копия вопроса с другим порядком ответов; остальные поля сохраняются
    func withAnswers(_ answers: [Answer], correctIndex: Int) -> Question {
        Question(
            id: id,
            text: text,
            answers: answers,
            correctIndex: correctIndex,
            category: category,
            difficulty: difficulty
        )
    }
    
    /// Копия вопроса с перемешанными ответами; правильный ответ остаётся правильным
    func withShuffledAnswers() -> Question {
        guard answers.indices.contains(correctIndex) else { return self }
        let shuffled: [Answer]
        if isLastAnswerFixed, let last = answers.last {
            shuffled = answers.dropLast().shuffled() + [last]
        } else {
            shuffled = answers.shuffled()
        }
        let correctAnswerId = answers[correctIndex].id
        guard let newCorrectIndex = shuffled.firstIndex(where: { $0.id == correctAnswerId }) else { return self }
        return withAnswers(shuffled, correctIndex: newCorrectIndex)
    }
}

struct Answer: Codable, Identifiable, Equatable {
    let id: String
    let text: String

    /// «Всё перечисленное», «Оба», «All of the above» и т. п. — такой ответ имеет смысл только после остальных.
    /// Те же шаблоны в scripts/check_questions.py
    var refersToOtherAnswers: Bool {
        let range = NSRange(text.startIndex..., in: text)
        return Self.aggregatePatterns.contains { $0.firstMatch(in: text, range: range) != nil }
    }

    private static let aggregatePatterns: [NSRegularExpression] = [
        #"\bвс[её]\s+(выше\s*)?(перечисленн|сказанн|названн|указанн)"#,
        #"\bвс[её]\s+вышеперечисленн"#,
        #"\bвсе\s+(варианты|ответы|эти)\b"#,
        #"\bвсеми\s+(выше\s*)?перечисленн"#,
        #"^\s*(на\s+)?(оба|обе|обоих)\b"#,
        #"\bни\s+(один|одно|одна)\s+из\s+(выше\s*)?(перечисленн|вариант|ответ|них|этих)"#,
        #"\ball\s+(of\s+)?(the\s+)?(above|listed|mentioned|these|options|answers)\b"#,
        #"\ball\s+of\s+them\b"#,
        #"\bnone\s+of\s+(the\s+above|these|them)\b"#,
        #"^\s*(on\s+)?both\b"#
    ].compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var localizedName: String {
        switch self {
        case .easy:
            return "difficulty.easy".localized
        case .medium:
            return "difficulty.medium".localized
        case .hard:
            return "difficulty.hard".localized
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
    /// Отвеченные вопросы: при досрочном завершении процент считается от них
    let totalQuestions: Int
    let correctAnswers: Int
    let percentage: Double
    let timeSpent: TimeInterval
    /// Сколько вопросов было в сессии, если её завершили досрочно; nil — пройдена до конца
    var plannedQuestions: Int? = nil
}
