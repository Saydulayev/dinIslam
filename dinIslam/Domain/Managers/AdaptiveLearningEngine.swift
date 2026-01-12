//
//  AdaptiveLearningEngine.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import Foundation

final class AdaptiveLearningEngine {
    private let quizHistoryLimit = 20
    private let examHistoryLimit = 20

    func applyQuizSummary(_ summary: QuizSessionSummary, to profile: inout UserProfile) -> [LearningRecommendation] {
        var progress = profile.progress

        progress.totalQuestionsAnswered += summary.totalQuestions
        progress.correctAnswers += summary.correctAnswers
        progress.incorrectAnswers += summary.incorrectAnswers
        progress.averageQuizScore = calculateNewAverage(
            currentAverage: progress.averageQuizScore,
            totalSessions: progress.quizHistory.count,
            newScore: summary.percentage
        )
        progress.currentStreak = summary.percentage >= 80 ? progress.currentStreak + 1 : 0
        if progress.currentStreak > progress.longestStreak {
            progress.longestStreak = progress.currentStreak
        }
        progress.lastActivityAt = summary.completedAt

        updateDifficultyStats(&progress, summary: summary)
        updateTopicProgress(&progress, summary: summary)

        let historyEntry = QuizHistoryEntry(
            date: summary.completedAt,
            percentage: summary.percentage,
            correctAnswers: summary.correctAnswers,
            totalQuestions: summary.totalQuestions,
            difficultyBreakdown: summary.difficultyBreakdown.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value },
            topicBreakdown: summary.topicBreakdown
        )
        progress.quizHistory.insert(historyEntry, at: 0)
        if progress.quizHistory.count > quizHistoryLimit {
            progress.quizHistory.removeLast()
        }

        let recommendations = generateRecommendationsInternal(for: progress)
        progress.recommendations = recommendations
        progress.masteryLevel = overallMasteryLevel(from: progress.averageQuizScore, streak: progress.currentStreak)

        profile.progress = progress
        profile.metadata.updatedAt = Date()
        return recommendations
    }

    func applyExamSummary(_ summary: ExamSessionSummary, to profile: inout UserProfile) {
        var progress = profile.progress
        progress.examsTaken += 1
        if summary.passed {
            progress.examsPassed += 1
        }
        progress.lastActivityAt = summary.completedAt

        let historyEntry = ExamHistoryEntry(
            date: summary.completedAt,
            percentage: summary.percentage,
            duration: summary.duration,
            correctAnswers: summary.correctAnswers,
            totalQuestions: summary.totalQuestions,
            passed: summary.passed,
            configuration: ExamConfigurationSnapshot(configuration: summary.result.configuration)
        )
        progress.examHistory.insert(historyEntry, at: 0)
        if progress.examHistory.count > examHistoryLimit {
            progress.examHistory.removeLast()
        }

        progress.recommendations = generateRecommendationsInternal(for: progress)
        progress.recommendations = generateRecommendationsInternal(for: progress)
        profile.progress = progress
        profile.metadata.updatedAt = Date()
    }

    func selectQuestions(
        from allQuestions: [Question],
        progress: ProfileProgress?,
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question] {
        guard let progress else {
            return defaultSelection(from: allQuestions, usedQuestionIds: usedQuestionIds, sessionCount: sessionCount)
        }

        var selection: [Question] = []
        let weakTopics = Set(progress.topicProgress.filter { $0.masteryLevel == .novice || $0.masteryLevel == .learning }.map(\.topicId))
        let moderateTopics = Set(progress.topicProgress.filter { $0.masteryLevel == .proficient }.map(\.topicId))

        let newQuestions = allQuestions.filter { !usedQuestionIds.contains($0.id) }
        let reusedQuestions = allQuestions.filter { usedQuestionIds.contains($0.id) }

        // Приоритет - слабые темы
        let weakTopicQuestions = newQuestions.filter { weakTopics.contains($0.category) }
        selection.append(contentsOf: Array(weakTopicQuestions.shuffled().prefix(sessionCount / 2)))

        // Второй приоритет - средние темы и средняя сложность
        if selection.count < sessionCount {
            let mediumDifficulty = newQuestions.filter {
                $0.difficulty != .hard &&
                (moderateTopics.contains($0.category) || weakTopics.contains($0.category))
            }
            let needed = sessionCount - selection.count
            selection.append(contentsOf: Array(mediumDifficulty.shuffled().prefix(needed)))
        }

        // Если не набрали, добавляем оставшиеся новые вопросы
        if selection.count < sessionCount {
            let remainingNewQuestions = newQuestions.filter { question in
                !selection.contains(where: { $0.id == question.id })
            }
            let needed = sessionCount - selection.count
            selection.append(contentsOf: Array(remainingNewQuestions.shuffled().prefix(needed)))
        }

        // Если все еще не хватает, добавляем повторные вопросы (для закрепления)
        if selection.count < sessionCount {
            let needed = sessionCount - selection.count
            selection.append(contentsOf: Array(reusedQuestions.shuffled().prefix(needed)))
        }

        if selection.count > sessionCount {
            selection = Array(selection.prefix(sessionCount))
        }

        return selection
    }

    func computeOverallMastery(averageScore: Double, streak: Int) -> MasteryLevel {
        overallMasteryLevel(from: averageScore, streak: streak)
    }

    func generateRecommendations(for progress: ProfileProgress) -> [LearningRecommendation] {
        generateRecommendationsInternal(for: progress)
    }

    // MARK: - Private Helpers
    private func defaultSelection(from questions: [Question], usedQuestionIds: Set<String>, sessionCount: Int) -> [Question] {
        let newQuestions = questions.filter { !usedQuestionIds.contains($0.id) }
        if newQuestions.count >= sessionCount {
            return Array(newQuestions.shuffled().prefix(sessionCount))
        }

        var selection = newQuestions
        if selection.count < sessionCount {
            let remaining = sessionCount - selection.count
            let reusedQuestions = questions.filter { usedQuestionIds.contains($0.id) }
            selection.append(contentsOf: Array(reusedQuestions.shuffled().prefix(remaining)))
        }
        return selection
    }

    private func calculateNewAverage(currentAverage: Double, totalSessions: Int, newScore: Double) -> Double {
        let total = Double(totalSessions)
        guard total > 0 else { return newScore }
        return ((currentAverage * total) + newScore) / (total + 1.0)
    }

    private func updateDifficultyStats(_ progress: inout ProfileProgress, summary: QuizSessionSummary) {
        for (difficulty, count) in summary.difficultyBreakdown {
            guard count > 0 else { continue }
            if var stat = progress.difficultyStats.first(where: { $0.difficulty == difficulty }) {
                stat.totalAnswers += count
                stat.correctAnswers += summary.outcomes.filter { $0.difficulty == difficulty && $0.isCorrect }.count
                stat.adaptiveScore = Double(stat.correctAnswers) / Double(max(1, stat.totalAnswers)) * 100
                stat.masteryLevel = masteryLevel(for: stat.adaptiveScore)
                replaceDifficultyStat(&progress, stat: stat)
            } else {
                var stat = DifficultyPerformance(difficulty: difficulty)
                stat.totalAnswers = count
                stat.correctAnswers = summary.outcomes.filter { $0.difficulty == difficulty && $0.isCorrect }.count
                stat.adaptiveScore = Double(stat.correctAnswers) / Double(max(1, stat.totalAnswers)) * 100
                stat.masteryLevel = masteryLevel(for: stat.adaptiveScore)
                replaceDifficultyStat(&progress, stat: stat)
            }
        }
    }

    private func replaceDifficultyStat(_ progress: inout ProfileProgress, stat: DifficultyPerformance) {
        if let index = progress.difficultyStats.firstIndex(where: { $0.difficulty == stat.difficulty }) {
            progress.difficultyStats[index] = stat
        } else {
            progress.difficultyStats.append(stat)
        }
    }

    private func updateTopicProgress(_ progress: inout ProfileProgress, summary: QuizSessionSummary) {
        for outcome in summary.outcomes {
            if var topic = progress.topicProgress.first(where: { $0.topicId == outcome.category }) {
                topic.totalAnswers += 1
                if outcome.isCorrect {
                    topic.correctAnswers += 1
                    topic.streak += 1
                } else {
                    topic.streak = 0
                }
                topic.masteryLevel = masteryLevel(for: topicAccuracy(topic))
                topic.recommendedDifficulty = recommendedDifficulty(for: topic.masteryLevel)
                topic.lastActivityAt = summary.completedAt
                replaceTopicProgress(&progress, topic: topic)
            } else {
                var topic = TopicProgress(topicId: outcome.category, displayName: outcome.category)
                topic.totalAnswers = 1
                if outcome.isCorrect {
                    topic.correctAnswers = 1
                    topic.streak = 1
                }
                topic.masteryLevel = masteryLevel(for: topicAccuracy(topic))
                topic.recommendedDifficulty = recommendedDifficulty(for: topic.masteryLevel)
                topic.lastActivityAt = summary.completedAt
                replaceTopicProgress(&progress, topic: topic)
            }
        }
    }

    private func topicAccuracy(_ topic: TopicProgress) -> Double {
        guard topic.totalAnswers > 0 else { return 0 }
        return Double(topic.correctAnswers) / Double(topic.totalAnswers) * 100
    }

    private func replaceTopicProgress(_ progress: inout ProfileProgress, topic: TopicProgress) {
        if let index = progress.topicProgress.firstIndex(where: { $0.topicId == topic.topicId }) {
            progress.topicProgress[index] = topic
        } else {
            progress.topicProgress.append(topic)
        }
    }

    private func masteryLevel(for accuracy: Double) -> MasteryLevel {
        switch accuracy {
        case ..<50:
            return .novice
        case 50..<70:
            return .learning
        case 70..<90:
            return .proficient
        default:
            return .expert
        }
    }

    private func overallMasteryLevel(from averageScore: Double, streak: Int) -> MasteryLevel {
        switch averageScore {
        case ..<50:
            return .novice
        case 50..<70:
            return .learning
        case 70..<90:
            return streak >= 5 ? .expert : .proficient
        default:
            return .expert
        }
    }

    private func recommendedDifficulty(for mastery: MasteryLevel) -> Difficulty? {
        switch mastery {
        case .novice:
            return .easy
        case .learning:
            return .medium
        case .proficient, .expert:
            return .hard
        }
    }

    private func generateRecommendationsInternal(for progress: ProfileProgress) -> [LearningRecommendation] {
        var recommendations: [LearningRecommendation] = []

        if let weakestTopic = progress.topicProgress.min(by: { topicAccuracy($0) < topicAccuracy($1) }),
           topicAccuracy(weakestTopic) < 70 {
            let message = String(
                format: NSLocalizedString("profile.recommendation.focusTopic", comment: "Focus topic recommendation"),
                weakestTopic.displayName ?? weakestTopic.topicId
            )
            let recommendation = LearningRecommendation(
                type: .focusTopic,
                title: NSLocalizedString("profile.recommendation.focusTopic.title", comment: ""),
                message: message,
                topicId: weakestTopic.topicId,
                targetDifficulty: weakestTopic.recommendedDifficulty
            )
            recommendations.append(recommendation)
        }

        if let highScore = progress.difficultyStats.first(where: { $0.masteryLevel == .expert || $0.adaptiveScore > 90 }) {
            let message = String(
                format: NSLocalizedString("profile.recommendation.challenge", comment: "Challenge recommendation"),
                highScore.difficulty.localizedName
            )
            let recommendation = LearningRecommendation(
                type: .increaseDifficulty,
                title: NSLocalizedString("profile.recommendation.challenge.title", comment: ""),
                message: message,
                targetDifficulty: .hard
            )
            recommendations.append(recommendation)
        }

        if progress.currentStreak >= 3 {
            let message = NSLocalizedString("profile.recommendation.maintainStreak", comment: "Maintain streak recommendation")
            let recommendation = LearningRecommendation(
                type: .maintainStreak,
                title: NSLocalizedString("profile.recommendation.maintainStreak.title", comment: ""),
                message: message
            )
            recommendations.append(recommendation)
        }

        return recommendations
    }
}

