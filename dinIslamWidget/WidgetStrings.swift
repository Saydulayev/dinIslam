//
//  WidgetStrings.swift
//  dinIslamWidget
//
//  Тексты виджета на языке приложения: его выбирают в настройках приложения,
//  и он может отличаться от языка системы.
//

import Foundation

struct WidgetStrings {
    let languageCode: String
    private let bundle: Bundle

    init(languageCode: String) {
        self.languageCode = languageCode
        bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    /// Пока приложение не передало свой язык — как «Системный» в настройках приложения
    static var systemLanguageCode: String {
        Bundle.preferredLocalizations(from: ["ru", "en"]).first == "en" ? "en" : "ru"
    }

    func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// «дней подряд» в нужной форме
    func streakLabel(_ streak: Int) -> String {
        text(PluralRules.key(for: "widget.streak", count: streak, language: languageCode))
    }

    func dueReview(_ count: Int) -> String {
        String(format: text("widget.review.due"), count)
    }

    func todayStatus(streak: Int, isActiveToday: Bool) -> String {
        if isActiveToday {
            return text("widget.today.done")
        }
        return text(streak > 0 ? "widget.today.keep" : "widget.today.start")
    }
}
