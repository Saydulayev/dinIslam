//
//  StartView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

// MARK: - Particle Structure
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

struct StartView: View {
    @State private var viewModel: QuizViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingAchievements = false
    @State private var showingExamSettings = false
    @State private var showingExam = false
    @State private var examViewModel: ExamViewModel?
    @State private var logoGlowIntensity: Double = 0.5
    @State private var particles: [Particle] = []
    @State private var isGlowAnimationStarted: Bool = false
    
    // Кэшированный код языка для избежания синхронных операций
    @State private var cachedLanguageCode: String = "ru"
    
    // Task cancellation
    @State private var startQuizTask: Task<Void, Never>?
    
    // Particle animation timer
    @State private var particleTimer: Timer?
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManager, settingsManager: SettingsManager) {
        self.viewModel = QuizViewModel(quizUseCase: quizUseCase, statsManager: statsManager, settingsManager: settingsManager)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // App Title - по центру экрана
                VStack(spacing: 16) {
                    ZStack {
                        // Фоновое свечение
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(0.2 * logoGlowIntensity), .purple.opacity(0.1 * logoGlowIntensity), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                        
                        // Основное изображение
                        Image("image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.4 * logoGlowIntensity), radius: 20, x: 0, y: 10)
                            .shadow(color: .purple.opacity(0.3 * logoGlowIntensity), radius: 30, x: 0, y: 0)
                        
                        // Магические частицы
                        ForEach(particles) { particle in
                            Circle()
                                .fill(.yellow.opacity(particle.opacity))
                                .frame(width: particle.size, height: particle.size)
                                .offset(x: particle.x, y: particle.y)
                                .blur(radius: 1)
                        }
                    }
                    
                    LocalizedText("app.name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    LocalizedText("start.description")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom section with average score and buttons
                VStack(spacing: 24) {
                    // Average Score
                    if statsManager.hasRecentGames() {
                        VStack(spacing: 8) {
                            LocalizedText("start.averageScore")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(Int(statsManager.getAverageRecentScore()))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            
                            Text(String(format: NSLocalizedString("start.basedOnGames", comment: ""), statsManager.getRecentGamesCount()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    } else {
                        VStack(spacing: 8) {
                            LocalizedText("start.noGamesYet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("—")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Regular Quiz Button
                        Button(action: {
                            startQuizTask?.cancel()
                            startQuizTask = Task {
                                await viewModel.startQuiz(language: cachedLanguageCode)
                            }
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    LocalizedText(viewModel.isLoading ? "start.loading" : "start.begin")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    LocalizedText("start.beginDescription")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Exam Mode Button
                        Button(action: {
                            showingExamSettings = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    LocalizedText("start.examMode")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    LocalizedText("start.examModeDescription")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationDestination(isPresented: .constant({
                if case .active(.playing) = viewModel.state { return true }
                return false
            }())) {
                QuizView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: .constant({
                if case .completed(.finished) = viewModel.state { return true }
                return false
            }())) {
                ResultView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(viewModel: SettingsViewModel(settingsManager: settingsManager))
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingExamSettings) {
                ExamSettingsView { configuration in
                    startExam(with: configuration)
                }
                .environmentObject(settingsManager)
            }
            .navigationDestination(isPresented: $showingExam) {
                if let examViewModel = examViewModel {
                    ExamView(viewModel: examViewModel)
                }
            }
            .navigationDestination(isPresented: $showingStats) {
                StatsView(statsManager: statsManager)
            }
            .navigationDestination(isPresented: $showingAchievements) {
                AchievementsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingStats = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingAchievements = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("error.title".localized,
                   isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("error.ok".localized) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                // Clear app badge when app is opened
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
                
                // Кэширование кода языка асинхронно
                Task {
                    cachedLanguageCode = settingsManager.settings.language.locale?.language.languageCode?.identifier ?? "ru"
                }
                
                // Предзагрузка вопросов для улучшения UX
                Task {
                    await EnhancedDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
                        for: ["ru", "en"]
                    )
                }
                
                // Анимация свечения логотипа (только если еще не запущена)
                if !isGlowAnimationStarted {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        logoGlowIntensity = 1.0
                    }
                    isGlowAnimationStarted = true
                }
                
                // Создание частиц (только если их еще нет)
                if particles.isEmpty {
                    createParticles()
                }
                
                // Анимация частиц (только если таймер не запущен)
                if particleTimer == nil {
                    startParticleAnimation()
                }
            }
        }
        .onDisappear {
            // Cancel pending tasks when view disappears
            startQuizTask?.cancel()
            
            // Останавливаем таймер частиц
            particleTimer?.invalidate()
            particleTimer = nil
        }
    }
    
    private func startExam(with configuration: ExamConfiguration) {
        let container = DIContainer.shared
        let examViewModel = ExamViewModel(
            examUseCase: container.examUseCase,
            examStatisticsManager: container.examStatisticsManager,
            settingsManager: settingsManager
        )
        
        self.examViewModel = examViewModel
        showingExam = true
        
        Task {
            await examViewModel.startExam(configuration: configuration, language: cachedLanguageCode)
        }
    }
    
    // MARK: - Particle Functions
    private func createParticles() {
        particles = (0..<12).map { _ in
            Particle(
                x: Double.random(in: -80...80),
                y: Double.random(in: -80...80),
                opacity: Double.random(in: 0.3...0.8),
                size: Double.random(in: 2...6),
                velocityX: Double.random(in: -0.5...0.5),
                velocityY: Double.random(in: -0.5...0.5),
                life: Double.random(in: 0.5...1.0)
            )
        }
    }
    
    private func startParticleAnimation() {
        // Останавливаем существующий таймер, если он есть
        particleTimer?.invalidate()
        
        // Создаем новый таймер
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].x += particles[i].velocityX
            particles[i].y += particles[i].velocityY
            particles[i].life -= 0.01
            particles[i].opacity = particles[i].life * 0.8
            
            // Если частица угасла, создаем новую
            if particles[i].life <= 0 {
                particles[i] = Particle(
                    x: Double.random(in: -80...80),
                    y: Double.random(in: -80...80),
                    opacity: Double.random(in: 0.3...0.8),
                    size: Double.random(in: 2...6),
                    velocityX: Double.random(in: -0.5...0.5),
                    velocityY: Double.random(in: -0.5...0.5),
                    life: Double.random(in: 0.5...1.0)
                )
            }
        }
    }
}

#Preview {
    StartView(
        quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()),
        statsManager: StatsManager(),
        settingsManager: SettingsManager()
    )
    .environmentObject(SettingsManager())
}
