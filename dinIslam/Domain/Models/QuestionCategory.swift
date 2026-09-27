//
//  QuestionCategory.swift
//  dinIslam
//
//  Темы вопросов. В JSON хранится стабильный id (ключ "cat"),
//  название локализуется в приложении, поэтому статистика не зависит от языка.
//

import Foundation

enum QuestionCategory: String, CaseIterable, Identifiable {
    case aqida
    case pillars
    case prophets
    case seerah
    case companions
    case quran
    case fiqh
    case history
    case akhlaq

    /// Категория вопросов, у которых тема ещё не указана
    static let generalId = "general"

    var id: String { rawValue }

    var localizedName: String {
        "category.\(rawValue)".localized
    }

    var icon: String {
        switch self {
        case .aqida: return "sun.max.fill"
        case .pillars: return "building.columns.fill"
        case .prophets: return "person.2.fill"
        case .seerah: return "moon.stars.fill"
        case .companions: return "person.3.fill"
        case .quran: return "book.closed.fill"
        case .fiqh: return "scalemass.fill"
        case .history: return "scroll.fill"
        case .akhlaq: return "heart.fill"
        }
    }

    static func displayName(for categoryId: String) -> String {
        QuestionCategory(rawValue: categoryId)?.localizedName ?? "category.general".localized
    }

    static func icon(for categoryId: String) -> String {
        QuestionCategory(rawValue: categoryId)?.icon ?? "tag"
    }
}
