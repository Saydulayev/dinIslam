//
//  RemoteQuestion.swift
//  dinIslam
//
//  Модель вопроса в файлах questions.json / questions_en.json (GitHub и встроенные в приложение).
//

import Foundation

// MARK: - Remote Question Models

// Поддержка обоих форматов: старый (id/text/answers с id) и новый (id/question/answers как массив строк)
struct RemoteQuestion: Codable {
    // ID может быть строкой или числом
    let id: RemoteQuestionID
    let text: String?
    let question: String?  // Новый формат использует "question" вместо "text"
    let answers: RemoteAnswers
    let correctIndex: Int
    let category: String?
    let difficulty: String?
    let explanation: String?
    
    // Определяем текст вопроса из любого формата
    var questionText: String {
        return text ?? question ?? ""
    }
    
    // Определяем категорию с дефолтным значением
    var questionCategory: String {
        guard let category, !category.isEmpty else { return QuestionCategory.generalId }
        return category
    }
    
    func toQuestion() -> Question {
        // Преобразуем ID в строку
        let questionId: String
        switch id {
        case .string(let str):
            questionId = str
        case .int(let num):
            questionId = String(num)
        }
        
        // Преобразуем answers в нужный формат
        let rawAnswers: [Answer]
        switch answers {
        case .objects(let answerObjects):
            rawAnswers = answerObjects.map { $0.toAnswer() }
        case .strings(let answerStrings):
            rawAnswers = answerStrings.enumerated().map { index, text in
                Answer(id: "a\(index + 1)", text: text)
            }
        }
        
        // Отсекаем пустые ответы (защита от лишних "" в JSON) и пересчитываем correctIndex
        let trimmed = rawAnswers.map { a in
            Answer(id: a.id, text: a.text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        var filtered: [(originalIndex: Int, answer: Answer)] = []
        for (idx, a) in trimmed.enumerated() {
            guard !a.text.isEmpty else { continue }
            filtered.append((originalIndex: idx, answer: a))
        }
        let questionAnswers = filtered.map(\.answer)
        let newCorrectIndex: Int
        if let found = filtered.firstIndex(where: { $0.originalIndex == correctIndex }) {
            newCorrectIndex = found
        } else {
            newCorrectIndex = min(max(0, correctIndex), questionAnswers.count - 1)
        }
        
        // Определяем difficulty
        let questionDifficulty: Difficulty
        if let difficultyStr = difficulty,
           let parsedDifficulty = Difficulty(rawValue: difficultyStr.lowercased()) {
            questionDifficulty = parsedDifficulty
        } else {
            questionDifficulty = .medium
        }
        
        let finalAnswers = questionAnswers.isEmpty ? rawAnswers : questionAnswers
        let finalCorrectIndex = questionAnswers.isEmpty ? correctIndex : newCorrectIndex
        let safeCorrectIndex = finalAnswers.isEmpty ? 0 : max(0, min(finalCorrectIndex, finalAnswers.count - 1))

        return Question(
            id: questionId,
            text: questionText,
            answers: finalAnswers,
            correctIndex: safeCorrectIndex,
            category: questionCategory,
            difficulty: questionDifficulty,
            explanation: explanation.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, question, answers, correctIndex, category, difficulty, explanation
        case q, a, c // Короткие ключи для компактного JSON
        case cat, d, exp // Тема, сложность, пояснение (старые версии приложения их не читают)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Обрабатываем ID (может быть строкой или числом)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = .string(stringId)
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = .int(intId)
        } else {
            throw DecodingError.typeMismatch(
                RemoteQuestionID.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.id],
                    debugDescription: "ID must be either String or Int"
                )
            )
        }
        
        // Текст вопроса: text | question | q (короткий)
        text = try? container.decode(String.self, forKey: .text)
        question = (try? container.decode(String.self, forKey: .question))
            ?? (try? container.decode(String.self, forKey: .q))
        
        // Answers: массив объектов, массив строк, или короткий ключ "a"
        if let answerObjects = try? container.decode([RemoteAnswer].self, forKey: .answers) {
            answers = .objects(answerObjects)
        } else if let answerStrings = try? container.decode([String].self, forKey: .answers) {
            answers = .strings(answerStrings)
        } else if let answerStrings = try? container.decode([String].self, forKey: .a) {
            answers = .strings(answerStrings)
        } else {
            throw DecodingError.typeMismatch(
                RemoteAnswers.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.answers],
                    debugDescription: "Answers must be either array of objects or array of strings"
                )
            )
        }
        
        // correctIndex или короткий "c"
        if let c = try? container.decode(Int.self, forKey: .correctIndex) {
            correctIndex = c
        } else if let c = try? container.decode(Int.self, forKey: .c) {
            correctIndex = c
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.correctIndex,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "correctIndex or c is required"
                )
            )
        }
        category = (try? container.decode(String.self, forKey: .cat))
            ?? (try? container.decode(String.self, forKey: .category))
        difficulty = (try? container.decode(String.self, forKey: .d))
            ?? (try? container.decode(String.self, forKey: .difficulty))
        explanation = (try? container.decode(String.self, forKey: .exp))
            ?? (try? container.decode(String.self, forKey: .explanation))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Кодируем ID
        switch id {
        case .string(let str):
            try container.encode(str, forKey: .id)
        case .int(let num):
            try container.encode(num, forKey: .id)
        }
        
        // Кодируем текст (приоритет text над question для обратной совместимости)
        if let text = text {
            try container.encode(text, forKey: .text)
        } else if let question = question {
            try container.encode(question, forKey: .question)
        }
        
        // Кодируем answers
        switch answers {
        case .objects(let answerObjects):
            try container.encode(answerObjects, forKey: .answers)
        case .strings(let answerStrings):
            try container.encode(answerStrings, forKey: .answers)
        }
        
        try container.encode(correctIndex, forKey: .correctIndex)
        if let category = category {
            try container.encode(category, forKey: .category)
        }
        if let difficulty = difficulty {
            try container.encode(difficulty, forKey: .difficulty)
        }
        if let explanation = explanation {
            try container.encode(explanation, forKey: .explanation)
        }
    }
}

enum RemoteQuestionID: Codable {
    case string(String)
    case int(Int)
}

enum RemoteAnswers: Codable {
    case objects([RemoteAnswer])
    case strings([String])
}

struct RemoteAnswer: Codable {
    let id: String?
    let text: String
    
    func toAnswer() -> Answer {
        return Answer(id: id ?? UUID().uuidString, text: text)
    }
}
