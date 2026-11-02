//
//  QuestionBookmarks.swift
//  dinIslam
//
//  Закладки: вопросы, к которым пользователь хочет вернуться. Снятая закладка не удаляется,
//  а хранится с временем снятия — иначе при синхронизации она вернулась бы с другого устройства.
//

import Foundation

struct BookmarkEntry: Codable, Equatable {
    var isBookmarked: Bool
    var updatedAt: Date
}

struct QuestionBookmarks: Codable, Equatable {
    /// id вопроса → отмечен ли и когда изменён
    private(set) var entries: [String: BookmarkEntry] = [:]

    init(entries: [String: BookmarkEntry] = [:]) {
        self.entries = entries
    }

    var ids: Set<String> {
        Set(entries.filter(\.value.isBookmarked).keys)
    }

    var count: Int {
        entries.values.filter(\.isBookmarked).count
    }

    var isEmpty: Bool {
        count == 0
    }

    /// Сначала отмеченные последними
    var orderedIds: [String] {
        entries
            .filter(\.value.isBookmarked)
            .sorted { $0.value.updatedAt != $1.value.updatedAt ? $0.value.updatedAt > $1.value.updatedAt : $0.key < $1.key }
            .map(\.key)
    }

    func contains(_ questionId: String) -> Bool {
        entries[questionId]?.isBookmarked ?? false
    }

    mutating func set(_ questionId: String, isBookmarked: Bool, at date: Date) {
        guard contains(questionId) != isBookmarked else { return }
        entries[questionId] = BookmarkEntry(isBookmarked: isBookmarked, updatedAt: date)
    }

    /// Слияние с другим устройством: по каждому вопросу побеждает более позднее изменение,
    /// при равном времени — закладка остаётся. Результат не зависит от порядка
    static func merged(_ lhs: QuestionBookmarks, _ rhs: QuestionBookmarks) -> QuestionBookmarks {
        let entries = lhs.entries.merging(rhs.entries) { left, right in
            if left.updatedAt != right.updatedAt {
                return left.updatedAt > right.updatedAt ? left : right
            }
            return left.isBookmarked ? left : right
        }
        return QuestionBookmarks(entries: entries)
    }
}

// MARK: - Decoding
// Отсутствующее поле получает значение по умолчанию (см. StoredDataDecoding.swift)

extension BookmarkEntry {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isBookmarked = container.decode(.isBookmarked, default: false)
        updatedAt = container.decode(.updatedAt, default: .distantPast)
    }
}

extension QuestionBookmarks {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entries = container.decode(.entries, default: [:])
    }
}
