//
//  StartViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import SwiftUI
import Observation
import UserNotifications
import UIKit

@MainActor
@Observable
final class StartViewModel {
    // MARK: - Dependencies
    let quizViewModel: QuizViewModel
    let statsManager: StatsManager
    let settingsManager: SettingsManager
    let profileManager: ProfileManager

    private let examUseCase: ExamUseCaseProtocol
    let examStatisticsManager: ExamStatisticsManager
    @ObservationIgnored private let achievementManager: AchievementManager
    @ObservationIgnored private let quizUseCase: QuizUseCaseProtocol
    @ObservationIgnored private let questionPoolProgressManager: QuestionPoolProgressManaging
    
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
        achievementManager: AchievementManager,
        questionsPreloading: QuestionsPreloading,
        questionPoolProgressManager: QuestionPoolProgressManaging,
        quizUseCase: QuizUseCaseProtocol,
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
        self.achievementManager = achievementManager
        self.quizUseCase = quizUseCase
        self.questionPoolProgressManager = questionPoolProgressManager
        
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
        
        self.cachedLanguageCode = settingsManager.settings.language.languageCode
    }


    // MARK: - Lifecycle
    func onAppear() {
        lifecycleManager.onAppear(
            onLanguageCodeUpdate: { [weak self] newCode in
                self?.cachedLanguageCode = newCode
            },
            onProfileSync: { [weak self] in
                await self?.profileManager.syncNow()
            }
        )
        visualEffectsManager.startGlowAnimationIfNeeded()
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
            let snapshot = StartRoute.ResultSnapshot(
                from: quizResult,
                report: quizViewModel.lastSessionReport,
                kind: quizViewModel.sessionKind
            )
            navigationCoordinator.showResult(snapshot)
            navigationPath = navigationCoordinator.navigationPath
        default:
            break
        }
    }

    // MARK: - Actions
    func startDailyPractice() {
        startQuiz(kind: .daily)
    }
    
    func startTopicQuiz(_ category: QuestionCategory) {
        startQuiz(kind: .topic(category))
    }
    
    /// «Продолжить» на экране результата: после викторины по теме — снова та же тема,
    /// после остальных сессий — обычная викторина
    func playAgain(after kind: QuizSessionKind) {
        resetQuiz()
        if case .topic(let category) = kind {
            startTopicQuiz(category)
        } else {
            startQuiz()
        }
    }
    
    func topicsProgress() async throws -> [TopicBankProgress] {
        try await quizUseCase.topicsProgress(language: cachedLanguageCode)
    }
    
    /// Повторение ошибок в том же стеке навигации, что и викторина
    func startReview(scope: MistakesReviewScope) {
        navigationCoordinator.resetNavigation()
        navigationPath = navigationCoordinator.navigationPath
        quizViewModel.restartQuiz()
        startQuizTask?.cancel()
        startQuizTask = Task { [weak self, cachedLanguageCode] in
            guard let self = self else { return }
            self.navigationCoordinator.showQuiz()
            self.navigationPath = self.navigationCoordinator.navigationPath
            await self.quizViewModel.startMistakesReview(language: cachedLanguageCode, scope: scope)
            self.returnToStartIfSessionFailed()
        }
    }
    
    func startQuiz(kind: QuizSessionKind = .standard) {
        navigationCoordinator.resetNavigation()
        navigationPath = navigationCoordinator.navigationPath
        startQuizTask?.cancel()
        startQuizTask = Task { [weak self, cachedLanguageCode] in
            guard let self = self else { return }
            
            // Банк пройден — экран завершения (ежедневная практика доступна и после прохождения банка)
            if kind == .standard {
                do {
                    let completionInfo = try await self.quizUseCase.isBankCompleted(language: cachedLanguageCode)
                    let isReviewMode = self.isReviewMode()
                    
                    if completionInfo.isCompleted && !isReviewMode {
                        // Показываем экран завершения
                        self.navigationCoordinator.showBankCompletion(totalQuestions: completionInfo.totalQuestions)
                        self.navigationPath = self.navigationCoordinator.navigationPath
                        return
                    }
                } catch {
                    // В случае ошибки продолжаем с обычной логикой
                }
            }
            
            // Обычный запуск викторины
            self.navigationCoordinator.showQuiz()
            self.navigationPath = self.navigationCoordinator.navigationPath
            await self.quizViewModel.startQuiz(language: cachedLanguageCode, kind: kind)
            self.returnToStartIfSessionFailed()
        }
    }
    
    /// Ссылка из виджета: «к повторению» открывает повторение ошибок.
    /// Начатую викторину или экзамен ссылка не прерывает, а если повторять уже нечего — остаётся главный экран
    func openWidgetLink(_ url: URL) {
        guard url == WidgetLink.review, !isSessionInProgress, statsManager.dueReviewCount > 0 else { return }
        startReview(scope: .due)
    }
    
    private var isSessionInProgress: Bool {
        if examViewModel != nil { return true }
        if case .active = quizViewModel.state { return true }
        return false
    }
    
    /// Если сессия не началась (нет вопросов, ошибка сети), не оставляем пустой экран викторины
    private func returnToStartIfSessionFailed() {
        guard quizViewModel.state == .idle || quizViewModel.state == .error(.networkError) else { return }
        navigationCoordinator.resetNavigation()
        navigationPath = navigationCoordinator.navigationPath
    }
    
    private func isReviewMode() -> Bool {
        questionPoolProgressManager.isReviewMode(version: 1)
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
            statsManager: statsManager,
            achievementManager: achievementManager,
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
    
    func showExamHistory() {
        navigationCoordinator.showExamHistory()
        navigationPath = navigationCoordinator.navigationPath
    }
    
    func showTopics() {
        navigationCoordinator.showTopics()
        navigationPath = navigationCoordinator.navigationPath
    }
    
    // MARK: - Bank Completion Actions
    func resetQuestionPool() {
        questionPoolProgressManager.reset(version: 1)
        questionPoolProgressManager.setReviewMode(false, version: 1)
    }
    
    func enableReviewMode() {
        questionPoolProgressManager.setReviewMode(true, version: 1)
    }
}
