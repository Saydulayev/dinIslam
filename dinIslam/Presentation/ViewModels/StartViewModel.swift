//
//  StartViewModel.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 08.11.25.
//

import SwiftUI
import Observation
import UserNotifications
import UIKit

@MainActor
@Observable
final class StartViewModel {
    // MARK: - Nested Types
    struct Particle: Identifiable {
        let id = UUID()
        var x: Double
        var y: Double
        var opacity: Double
        var size: Double
        var velocityX: Double
        var velocityY: Double
        var life: Double
    }

    // MARK: - Dependencies
    let quizViewModel: QuizViewModel
    let statsManager: StatsManager
    let settingsManager: SettingsManager
    let profileManager: ProfileManager

    private let examUseCase: ExamUseCaseProtocol
    private let examStatisticsManager: ExamStatisticsManager
    private let enhancedContainer: EnhancedDIContainer

    // MARK: - Configuration
    private let particleVelocityRange: ClosedRange<Double> = -0.35...0.35
    private let particleSpeedMultiplier: Double = 0.65

    // MARK: - UI State
    var navigationPath = NavigationPath()
    var showingExamSettings = false

    var examViewModel: ExamViewModel?

    var logoGlowIntensity: Double = 0.5
    var particles: [Particle] = []
    var isGlowAnimationStarted = false
    var cachedLanguageCode: String

    // MARK: - Tasks
    private var startQuizTask: Task<Void, Never>?
    private var lastParticleUpdate: Date?

    // MARK: - Init
    init(
        quizViewModel: QuizViewModel,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        enhancedContainer: EnhancedDIContainer
    ) {
        self.quizViewModel = quizViewModel
        self.statsManager = statsManager
        self.settingsManager = settingsManager
        self.profileManager = profileManager
        self.examUseCase = examUseCase
        self.examStatisticsManager = examStatisticsManager
        self.enhancedContainer = enhancedContainer
        self.cachedLanguageCode = StartViewModel.languageCode(from: settingsManager)
    }

    convenience init(
        quizViewModel: QuizViewModel,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager
    ) {
        self.init(
            quizViewModel: quizViewModel,
            statsManager: statsManager,
            settingsManager: settingsManager,
            profileManager: profileManager,
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            enhancedContainer: EnhancedDIContainer.shared
        )
    }

    // MARK: - Lifecycle
    func onAppear() {
        clearBadge()
        cachedLanguageCode = Self.languageCode(from: settingsManager)
        preloadQuestions()
        startGlowAnimationIfNeeded()
        createParticlesIfNeeded()
        if profileManager.isSignedIn {
            Task {
                await profileManager.refreshFromCloud(mergeStrategy: .newest)
            }
        }
    }

    func onDisappear() {
        startQuizTask?.cancel()
        lastParticleUpdate = nil
    }

    func onLanguageChange() {
        cachedLanguageCode = Self.languageCode(from: settingsManager)
    }

    func onQuizStateChange(_ newState: QuizState) {
        switch newState {
        case .completed(.finished), .completed(.mistakesFinished):
            guard let quizResult = quizViewModel.quizResult else { return }
            let snapshot = StartRoute.ResultSnapshot(from: quizResult)
            navigationPath.append(StartRoute.result(snapshot))
        default:
            break
        }
    }

    // MARK: - Actions
    func startQuiz() {
        navigationPath = NavigationPath()
        startQuizTask?.cancel()
        navigationPath.append(StartRoute.quiz)
        startQuizTask = Task { [cachedLanguageCode, quizViewModel] in
            await quizViewModel.startQuiz(language: cachedLanguageCode)
        }
    }

    func resetQuiz() {
        navigationPath = NavigationPath()
        quizViewModel.restartQuiz()
    }

    func startExam(with configuration: ExamConfiguration) {
        let viewModel = ExamViewModel(
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            settingsManager: settingsManager
        )

        examViewModel = viewModel
        navigationPath.append(StartRoute.exam)

        Task {
            await viewModel.startExam(configuration: configuration, language: cachedLanguageCode)
        }
    }

    func finishExamSession() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        examViewModel?.restartExam()
        examViewModel = nil
    }

    func clearNewAchievements() {
        quizViewModel.clearNewAchievements()
    }

    func showStats() {
        navigationPath.append(StartRoute.stats)
    }

    func showAchievements() {
        navigationPath.append(StartRoute.achievements)
    }
    
    func showSettings() {
        navigationPath.append(StartRoute.settings)
    }

    func showProfile() {
        navigationPath.append(StartRoute.profile)
    }

    // MARK: - Particles & Animations
    private func startGlowAnimationIfNeeded() {
        guard !isGlowAnimationStarted else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            logoGlowIntensity = 1.0
        }
        isGlowAnimationStarted = true
    }

    private func createParticlesIfNeeded() {
        guard particles.isEmpty else { return }
        particles = (0..<12).map { _ in
            Particle(
                x: Double.random(in: -80...80),
                y: Double.random(in: -80...80),
                opacity: Double.random(in: 0.3...0.8),
                size: Double.random(in: 2...6),
                velocityX: Double.random(in: particleVelocityRange),
                velocityY: Double.random(in: particleVelocityRange),
                life: Double.random(in: 0.5...1.0)
            )
        }
        lastParticleUpdate = nil
    }

    func updateParticles(at date: Date) {
        guard !particles.isEmpty else {
            lastParticleUpdate = date
            return
        }

        let delta: Double
        if let lastParticleUpdate {
            delta = date.timeIntervalSince(lastParticleUpdate)
        } else {
            delta = 0
        }
        lastParticleUpdate = date

        guard delta > 0 else { return }

        let frameFactor = min(delta * 60.0, 1.0)

        for index in particles.indices {
            particles[index].x += particles[index].velocityX * frameFactor * particleSpeedMultiplier
            particles[index].y += particles[index].velocityY * frameFactor * particleSpeedMultiplier
            particles[index].life -= 0.01 * frameFactor
            particles[index].opacity = max(0, particles[index].life * 0.8)

            if particles[index].life <= 0 {
                particles[index] = Particle(
                    x: Double.random(in: -80...80),
                    y: Double.random(in: -80...80),
                    opacity: Double.random(in: 0.3...0.8),
                    size: Double.random(in: 2...6),
                    velocityX: Double.random(in: particleVelocityRange),
                    velocityY: Double.random(in: particleVelocityRange),
                    life: Double.random(in: 0.5...1.0)
                )
            }
        }
    }

    func particlesSnapshot(for date: Date) -> [Particle] {
        updateParticles(at: date)
        return particles
    }

    // MARK: - Helpers
    private func preloadQuestions() {
        Task {
            await enhancedContainer.enhancedQuizUseCase.preloadQuestions(for: ["ru", "en"])
        }
    }

    private func clearBadge() {
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    private static func languageCode(from settingsManager: SettingsManager) -> String {
        settingsManager.settings.language.locale?.language.languageCode?.identifier ?? "ru"
    }
}

