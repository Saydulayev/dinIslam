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

// MARK: - Achievement Types
enum AchievementType: String, Codable, CaseIterable {
    case firstQuiz = "first_quiz"
    case perfectScore = "perfect_score"
    case speedRunner = "speed_runner"
    case scholar = "scholar"
    case dedicated = "dedicated"
    case master = "master"
    case streak = "streak"
    case explorer = "explorer"
    case perfectionist = "perfectionist"
    case legend = "legend"
    
    // MARK: Dependency-injected helpers (preferred)
    func title(using localization: LocalizationProviding) -> String {
        switch self {
        case .firstQuiz:
            return localization.localizedString(for: "achievements.firstQuiz.title")
        case .perfectScore:
            return localization.localizedString(for: "achievements.perfectScore.title")
        case .speedRunner:
            return localization.localizedString(for: "achievements.speedRunner.title")
        case .scholar:
            return localization.localizedString(for: "achievements.scholar.title")
        case .dedicated:
            return localization.localizedString(for: "achievements.dedicated.title")
        case .master:
            return localization.localizedString(for: "achievements.master.title")
        case .streak:
            return localization.localizedString(for: "achievements.streak.title")
        case .explorer:
            return localization.localizedString(for: "achievements.explorer.title")
        case .perfectionist:
            return localization.localizedString(for: "achievements.perfectionist.title")
        case .legend:
            return localization.localizedString(for: "achievements.legend.title")
        }
    }
    
    func description(using localization: LocalizationProviding) -> String {
        switch self {
        case .firstQuiz:
            return localization.localizedString(for: "achievements.firstQuiz.description")
        case .perfectScore:
            return localization.localizedString(for: "achievements.perfectScore.description")
        case .speedRunner:
            return localization.localizedString(for: "achievements.speedRunner.description")
        case .scholar:
            return localization.localizedString(for: "achievements.scholar.description")
        case .dedicated:
            return localization.localizedString(for: "achievements.dedicated.description")
        case .master:
            return localization.localizedString(for: "achievements.master.description")
        case .streak:
            return localization.localizedString(for: "achievements.streak.description")
        case .explorer:
            return localization.localizedString(for: "achievements.explorer.description")
        case .perfectionist:
            return localization.localizedString(for: "achievements.perfectionist.description")
        case .legend:
            return localization.localizedString(for: "achievements.legend.description")
        }
    }
    
    func unlockedDescription(using localization: LocalizationProviding) -> String {
        switch self {
        case .firstQuiz:
            return localization.localizedString(for: "achievements.firstQuiz.description.unlocked")
        case .perfectScore:
            return localization.localizedString(for: "achievements.perfectScore.description.unlocked")
        case .speedRunner:
            return localization.localizedString(for: "achievements.speedRunner.description.unlocked")
        case .scholar:
            return localization.localizedString(for: "achievements.scholar.description.unlocked")
        case .dedicated:
            return localization.localizedString(for: "achievements.dedicated.description.unlocked")
        case .master:
            return localization.localizedString(for: "achievements.master.description.unlocked")
        case .streak:
            return localization.localizedString(for: "achievements.streak.description.unlocked")
        case .explorer:
            return localization.localizedString(for: "achievements.explorer.description.unlocked")
        case .perfectionist:
            return localization.localizedString(for: "achievements.perfectionist.description.unlocked")
        case .legend:
            return localization.localizedString(for: "achievements.legend.description.unlocked")
        }
    }
    
    func notification(using localization: LocalizationProviding) -> String {
        switch self {
        case .firstQuiz:
            return localization.localizedString(for: "achievements.firstQuiz.notification")
        case .perfectScore:
            return localization.localizedString(for: "achievements.perfectScore.notification")
        case .speedRunner:
            return localization.localizedString(for: "achievements.speedRunner.notification")
        case .scholar:
            return localization.localizedString(for: "achievements.scholar.notification")
        case .dedicated:
            return localization.localizedString(for: "achievements.dedicated.notification")
        case .master:
            return localization.localizedString(for: "achievements.master.notification")
        case .streak:
            return localization.localizedString(for: "achievements.streak.notification")
        case .explorer:
            return localization.localizedString(for: "achievements.explorer.notification")
        case .perfectionist:
            return localization.localizedString(for: "achievements.perfectionist.notification")
        case .legend:
            return localization.localizedString(for: "achievements.legend.notification")
        }
    }
    
    // MARK: Backward-compatible computed properties (deprecated)
    // These forward to GlobalLocalizationProvider.instance to avoid using LocalizationManager.shared
    // and to silence the warnings while you migrate call sites to the DI-based helpers above.
    @available(*, deprecated, message: "Use title(using:) with a LocalizationProviding instead")
    var localizedTitle: String {
        let provider: LocalizationProviding = GlobalLocalizationProvider.instance
        return self.title(using: provider)
    }
    
    @available(*, deprecated, message: "Use description(using:) with a LocalizationProviding instead")
    var localizedDescription: String {
        let provider: LocalizationProviding = GlobalLocalizationProvider.instance
        return self.description(using: provider)
    }
    
    @available(*, deprecated, message: "Use unlockedDescription(using:) with a LocalizationProviding instead")
    var localizedUnlockedDescription: String {
        let provider: LocalizationProviding = GlobalLocalizationProvider.instance
        return self.unlockedDescription(using: provider)
    }
    
    @available(*, deprecated, message: "Use notification(using:) with a LocalizationProviding instead")
    var localizedNotification: String {
        let provider: LocalizationProviding = GlobalLocalizationProvider.instance
        return self.notification(using: provider)
    }
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

