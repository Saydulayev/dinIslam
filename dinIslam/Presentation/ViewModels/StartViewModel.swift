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
    @ObservationIgnored private let enhancedQuizUseCase: (any EnhancedQuizUseCaseProtocol)?
    
    // Services via protocols
    @ObservationIgnored private let navigationCoordinator: StartNavigationCoordinating
    @ObservationIgnored private let visualEffectsManager: StartVisualEffectsManaging
    @ObservationIgnored private let lifecycleManager: StartLifecycleManaging
    @ObservationIgnored private let examViewModelFactory: ExamViewModelCreating

    // MARK: - UI State
    var navigationPath = NavigationPath() {
        didSet {
            navigationCoordinator.navigationPath = navigationPath
        }
    }
    var showingExamSettings = false

    var examViewModel: ExamViewModel?

    var logoGlowIntensity: Double {
        get { visualEffectsManager.logoGlowIntensity }
        set { visualEffectsManager.logoGlowIntensity = newValue }
    }
    var particles: [Particle] {
        get { visualEffectsManager.particles }
        set { visualEffectsManager.particles = newValue }
    }
    var isGlowAnimationStarted: Bool {
        get { visualEffectsManager.isGlowAnimationStarted }
        set { visualEffectsManager.isGlowAnimationStarted = newValue }
    }
    var cachedLanguageCode: String

    // MARK: - Tasks
    private var startQuizTask: Task<Void, Never>?

    // MARK: - Init
    init(
        quizViewModel: QuizViewModel,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        questionsPreloading: QuestionsPreloading,
        enhancedQuizUseCase: (any EnhancedQuizUseCaseProtocol)? = nil,
        navigationCoordinator: StartNavigationCoordinating? = nil,
        visualEffectsManager: StartVisualEffectsManaging? = nil,
        lifecycleManager: StartLifecycleManaging? = nil,
        examViewModelFactory: ExamViewModelCreating? = nil
    ) {
        self.quizViewModel = quizViewModel
        self.statsManager = statsManager
        self.settingsManager = settingsManager
        self.profileManager = profileManager
        self.examUseCase = examUseCase
        self.examStatisticsManager = examStatisticsManager
        self.enhancedQuizUseCase = enhancedQuizUseCase
        
        // Initialize services with default implementations if not provided
        let resolvedNavigationCoordinator = navigationCoordinator ?? DefaultStartNavigationCoordinator()
        self.navigationCoordinator = resolvedNavigationCoordinator
        // Sync initial navigation path
        self.navigationPath = resolvedNavigationCoordinator.navigationPath
        
        self.visualEffectsManager = visualEffectsManager ?? DefaultStartVisualEffectsManager()
        
        self.lifecycleManager = lifecycleManager ?? DefaultStartLifecycleManager(
            settingsManager: settingsManager,
            profileManager: profileManager,
            questionsPreloading: questionsPreloading
        )
        
        self.examViewModelFactory = examViewModelFactory ?? DefaultExamViewModelFactory()
        
        self.cachedLanguageCode = StartViewModel.languageCode(from: settingsManager)
    }

    convenience init(
        quizViewModel: QuizViewModel,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        enhancedContainer: EnhancedDIContainer
    ) {
        let questionsPreloading = DefaultQuestionsPreloadingService(
            enhancedQuizUseCase: enhancedContainer.enhancedQuizUseCase
        )
        self.init(
            quizViewModel: quizViewModel,
            statsManager: statsManager,
            settingsManager: settingsManager,
            profileManager: profileManager,
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            questionsPreloading: questionsPreloading,
            enhancedQuizUseCase: enhancedContainer.enhancedQuizUseCase
        )
    }
    

    // MARK: - Lifecycle
    func onAppear() {
        lifecycleManager.onAppear(
            onLanguageCodeUpdate: { [weak self] newCode in
                self?.cachedLanguageCode = newCode
            },
            onProfileSync: { [weak self] in
                await self?.profileManager.refreshFromCloud(mergeStrategy: .newest)
            }
        )
        visualEffectsManager.startGlowAnimationIfNeeded()
        visualEffectsManager.createParticlesIfNeeded()
    }

    func onDisappear() {
        lifecycleManager.onDisappear { [weak self] in
            self?.startQuizTask?.cancel()
        }
    }

    func onLanguageChange() {
        lifecycleManager.onLanguageChange(
            onLanguageCodeUpdate: { [weak self] newCode in
                self?.cachedLanguageCode = newCode
            }
        )
    }

    func onQuizStateChange(_ newState: QuizState) {
        switch newState {
        case .completed(.finished), .completed(.mistakesFinished):
            guard let quizResult = quizViewModel.quizResult else { return }
            let snapshot = StartRoute.ResultSnapshot(from: quizResult)
            navigationCoordinator.showResult(snapshot)
            navigationPath = navigationCoordinator.navigationPath
        default:
            break
        }
    }

    // MARK: - Actions
    func startQuiz() {
        navigationCoordinator.resetNavigation()
        navigationPath = navigationCoordinator.navigationPath
        startQuizTask?.cancel()
        startQuizTask = Task { [weak self, cachedLanguageCode] in
            guard let self = self else { return }
            
            // Проверяем завершение банка через enhancedQuizUseCase или quizUseCase
            if let enhancedUseCase = self.enhancedQuizUseCase {
                do {
                    let completionInfo = try await enhancedUseCase.isBankCompleted(language: cachedLanguageCode)
                    let isReviewMode = await self.isReviewMode()
                    
                    if completionInfo.isCompleted && !isReviewMode {
                        // Показываем экран завершения
                        await MainActor.run {
                            self.navigationCoordinator.showBankCompletion(totalQuestions: completionInfo.totalQuestions)
                            self.navigationPath = self.navigationCoordinator.navigationPath
                        }
                        return
                    }
                } catch {
                    // В случае ошибки продолжаем с обычной логикой
                }
            }
            
            // Обычный запуск викторины
            await MainActor.run {
                self.navigationCoordinator.showQuiz()
                self.navigationPath = self.navigationCoordinator.navigationPath
            }
            await self.quizViewModel.startQuiz(language: cachedLanguageCode)
        }
    }
    
    private func isReviewMode() async -> Bool {
        // Получаем доступ к questionPoolProgressManager через DefaultQuestionPoolProgressManager
        let manager = DefaultQuestionPoolProgressManager()
        return manager.isReviewMode(version: 1)
    }

    func resetQuiz() {
        navigationCoordinator.resetNavigation()
        navigationPath = navigationCoordinator.navigationPath
        quizViewModel.restartQuiz()
    }

    func startExam(with configuration: ExamConfiguration) {
        // Create feedback provider for exam
        let hapticManager = HapticManager(settingsManager: settingsManager)
        let soundManager = SoundManager(settingsManager: settingsManager)
        let feedbackProvider = DefaultQuizFeedbackProvider(
            hapticManager: hapticManager,
            soundManager: soundManager
        )
        
        let viewModel = examViewModelFactory.createExamViewModel(
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            feedbackProvider: feedbackProvider,
            settingsManager: settingsManager
        )

        examViewModel = viewModel
        navigationCoordinator.showExam()
        navigationPath = navigationCoordinator.navigationPath

        Task { [cachedLanguageCode] in
            await viewModel.startExam(configuration: configuration, language: cachedLanguageCode)
        }
    }

    func finishExamSession() {
        navigationCoordinator.finishExamSession()
        navigationPath = navigationCoordinator.navigationPath
        examViewModel?.restartExam()
        examViewModel = nil
    }

    func clearNewAchievements() {
        quizViewModel.clearNewAchievements()
    }

    func showAchievements() {
        navigationCoordinator.showAchievements()
        navigationPath = navigationCoordinator.navigationPath
    }
    
    func showSettings() {
        navigationCoordinator.showSettings()
        navigationPath = navigationCoordinator.navigationPath
    }

    func showProfile() {
        navigationCoordinator.showProfile()
        navigationPath = navigationCoordinator.navigationPath
    }
    
    // MARK: - Bank Completion Actions
    func resetQuestionPool() {
        let manager = DefaultQuestionPoolProgressManager()
        manager.reset(version: 1)
        manager.setReviewMode(false, version: 1)
    }
    
    func enableReviewMode() {
        let manager = DefaultQuestionPoolProgressManager()
        manager.setReviewMode(true, version: 1)
    }

    // MARK: - Particles & Animations
    func updateParticles(at date: Date) {
        visualEffectsManager.updateParticles(at: date)
    }

    func particlesSnapshot(for date: Date) -> [Particle] {
        return visualEffectsManager.particlesSnapshot(for: date)
    }

    // MARK: - Helpers
    private static func languageCode(from settingsManager: SettingsManager) -> String {
        settingsManager.settings.language.locale?.language.languageCode?.identifier ?? "ru"
    }
}

