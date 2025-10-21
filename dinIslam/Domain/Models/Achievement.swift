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
    
    var localizedTitle: String {
        switch self {
        case .firstQuiz:
            return LocalizationManager.shared.localizedString(for: "achievements.firstQuiz.title")
        case .perfectScore:
            return LocalizationManager.shared.localizedString(for: "achievements.perfectScore.title")
        case .speedRunner:
            return LocalizationManager.shared.localizedString(for: "achievements.speedRunner.title")
        case .scholar:
            return LocalizationManager.shared.localizedString(for: "achievements.scholar.title")
        case .dedicated:
            return LocalizationManager.shared.localizedString(for: "achievements.dedicated.title")
        case .master:
            return LocalizationManager.shared.localizedString(for: "achievements.master.title")
        case .streak:
            return LocalizationManager.shared.localizedString(for: "achievements.streak.title")
        case .explorer:
            return LocalizationManager.shared.localizedString(for: "achievements.explorer.title")
        case .perfectionist:
            return LocalizationManager.shared.localizedString(for: "achievements.perfectionist.title")
        case .legend:
            return LocalizationManager.shared.localizedString(for: "achievements.legend.title")
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .firstQuiz:
            return LocalizationManager.shared.localizedString(for: "achievements.firstQuiz.description")
        case .perfectScore:
            return LocalizationManager.shared.localizedString(for: "achievements.perfectScore.description")
        case .speedRunner:
            return LocalizationManager.shared.localizedString(for: "achievements.speedRunner.description")
        case .scholar:
            return LocalizationManager.shared.localizedString(for: "achievements.scholar.title")
        case .dedicated:
            return LocalizationManager.shared.localizedString(for: "achievements.dedicated.description")
        case .master:
            return LocalizationManager.shared.localizedString(for: "achievements.master.description")
        case .streak:
            return LocalizationManager.shared.localizedString(for: "achievements.streak.description")
        case .explorer:
            return LocalizationManager.shared.localizedString(for: "achievements.explorer.description")
        case .perfectionist:
            return LocalizationManager.shared.localizedString(for: "achievements.perfectionist.description")
        case .legend:
            return LocalizationManager.shared.localizedString(for: "achievements.legend.description")
        }
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
