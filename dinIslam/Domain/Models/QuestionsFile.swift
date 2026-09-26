//
//  QuestionsFile.swift
//  dinIslam
//
//  Чтение файлов с вопросами (GitHub и встроенные в приложение).
//  Неправильный вопрос пропускается, остальные загружаются.
//

import Foundation
import OSLog

enum QuestionsFile {
    /// Имя файла без расширения: questions.json — русский, questions_en.json — английский.
    static func name(for language: AppLanguage) -> String {
        language == .russian ? "questions" : "questions_en"
    }

    /// Вопросы, встроенные в приложение.
    static func loadBundled(for language: AppLanguage, bundle: Bundle = .main) throws -> [Question] {
        let fileName = name(for: language)
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw EnhancedQuestionsError.fileNotFound
        }
        let questions = try decode(Data(contentsOf: url))
        AppLogger.info("Loaded \(questions.count) bundled questions from \(fileName).json", category: AppLogger.data)
        return questions
    }

    /// Декодирует файл с вопросами; бросает ошибку, только если не осталось ни одного правильного вопроса.
    static func decode(_ data: Data) throws -> [Question] {
        let items = try JSONDecoder().decode([LossyDecodable<RemoteQuestion>].self, from: data)
        return try questions(from: items)
    }

    /// Преобразует декодированные элементы в вопросы, отбрасывая неправильные.
    static func questions(from items: [LossyDecodable<RemoteQuestion>]) throws -> [Question] {
        let decoded = items.compactMap(\.value)
        if decoded.count < items.count {
            AppLogger.warning("Skipped \(items.count - decoded.count) question(s) that could not be decoded", category: AppLogger.data)
        }
        let questions = QuestionValidator().validQuestions(from: decoded.map { $0.toQuestion() })
        guard !questions.isEmpty else {
            throw EnhancedQuestionsError.emptyData
        }
        return questions
    }
}

/// Элемент массива, который при ошибке декодирования становится nil, а не ломает весь массив.
struct LossyDecodable<Wrapped: Codable>: Codable {
    let value: Wrapped?

    init(from decoder: Decoder) throws {
        value = try? Wrapped(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
