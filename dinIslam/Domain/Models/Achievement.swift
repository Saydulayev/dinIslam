//
//  Achievement.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import SwiftUI

// MARK: - Achievement Model
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let type: AchievementType
    let requirement: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    // Preferred DI-based variant for use in Views/Call-sites that have a LocalizationProviding
    func displayDescription(using localization: LocalizationProviding) -> String {
        if isUnlocked {
            return type.unlockedDescription(using: localization)
        } else {
            return description
        }
    }
    
    init(id: String, title: String, description: String, icon: String, color: Color, type: AchievementType, requirement: Int, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.type = type
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

// MARK: - Codable Achievement for Storage
struct CodableAchievement: Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let colorName: String
    let type: AchievementType
    let requirement: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    init(from achievement: Achievement) {
        self.id = achievement.id
        self.title = achievement.title
        self.description = achievement.description
        self.icon = achievement.icon
        self.colorName = achievement.color.description
        self.type = achievement.type
        self.requirement = achievement.requirement
        self.isUnlocked = achievement.isUnlocked
        self.unlockedDate = achievement.unlockedDate
    }
    
    func toAchievement() -> Achievement {
        let color: Color
        switch colorName {
        case "blue": color = .blue
        case "yellow": color = .yellow
        case "orange": color = .orange
        case "purple": color = .purple
        case "red": color = .red
        case "cyan": color = .cyan
        case "green": color = .green
        case "pink": color = .pink
        case "indigo": color = .indigo
        default: color = .gray
        }
        
        return Achievement(
            id: id,
            title: title,
            description: description,
            icon: icon,
            color: color,
            type: type,
            requirement: requirement,
            isUnlocked: isUnlocked,
            unlockedDate: unlockedDate
        )
    }
}

// Достижение читается по `id`; остальные поля нужны только для записи в старом формате,
// поэтому отсутствующие получают значения по умолчанию (см. StoredDataDecoding.swift)
extension CodableAchievement {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = container.decode(.title, default: "")
        description = container.decode(.description, default: "")
        icon = container.decode(.icon, default: "")
        colorName = container.decode(.colorName, default: "")
        // Неизвестный тип (достижение из более новой версии) — запись пропускается
        type = try container.decode(AchievementType.self, forKey: .type)
        requirement = container.decode(.requirement, default: 0)
        isUnlocked = container.decode(.isUnlocked, default: false)
        unlockedDate = container.decodeOptional(.unlockedDate)
    }
}

// MARK: - Achievement Types
enum AchievementType: String, Codable, CaseIterable {
    case firstQuiz = "first_quiz"
    case examPassed = "exam_passed"
    case perfectScore = "perfect_score"
    case speedRunner = "speed_runner"
    case scholar = "scholar"
    case dedicated = "dedicated"
    case master = "master"
    case streak = "streak"
    case streakWeek = "streak_7"
    case streakMonth = "streak_30"
    case explorer = "explorer"
    case perfectionist = "perfectionist"
    case mistakesLearned = "mistakes_10"
    case mistakesMastered = "mistakes_50"
    case legend = "legend"
    
    /// Часть ключа строк: `achievements.<key>.title` и т. д.
    private var localizationKey: String {
        switch self {
        case .firstQuiz: return "firstQuiz"
        case .examPassed: return "examPassed"
        case .perfectScore: return "perfectScore"
        case .speedRunner: return "speedRunner"
        case .scholar: return "scholar"
        case .dedicated: return "dedicated"
        case .master: return "master"
        case .streak: return "streak"
        case .streakWeek: return "streakWeek"
        case .streakMonth: return "streakMonth"
        case .explorer: return "explorer"
        case .perfectionist: return "perfectionist"
        case .mistakesLearned: return "mistakesLearned"
        case .mistakesMastered: return "mistakesMastered"
        case .legend: return "legend"
        }
    }
    
    func title(using localization: LocalizationProviding) -> String {
        localization.localizedString(for: "achievements.\(localizationKey).title")
    }
    
    func description(using localization: LocalizationProviding) -> String {
        localization.localizedString(for: "achievements.\(localizationKey).description")
    }
    
    func unlockedDescription(using localization: LocalizationProviding) -> String {
        localization.localizedString(for: "achievements.\(localizationKey).description.unlocked")
    }
    
    func notification(using localization: LocalizationProviding) -> String {
        localization.localizedString(for: "achievements.\(localizationKey).notification")
    }
}

// MARK: - Achievement Context
/// Изучено разных вопросов текущего банка и его размер
struct BankProgress: Equatable {
    let studied: Int
    let total: Int
}

/// Всё, по чему открываются достижения. nil — данные не известны в этом месте
/// (например, экзамен не меняет пройденные вопросы): такие достижения не проверяются
struct AchievementContext {
    var stats: UserStats
    var dayStreak: Int
    var bankProgress: BankProgress?
    var examsPassed: Int?
}

// MARK: - Achievement Progress
struct AchievementProgress {
    let achievementType: AchievementType
    let currentProgress: Int
    let requirement: Int
    let isCompleted: Bool
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }
}

