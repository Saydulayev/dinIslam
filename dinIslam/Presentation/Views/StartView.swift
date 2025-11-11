//
//  StartView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import Observation
#if os(iOS)
import UIKit
#endif

enum StartRoute: Hashable {
    case quiz
    case result(ResultSnapshot)
    case stats
    case achievements
    case settings
    case profile
    case exam
    
    struct ResultSnapshot: Hashable {
        let totalQuestions: Int
        let correctAnswers: Int
        let percentage: Double
        let timeSpent: Double
        
        init(from result: QuizResult) {
            totalQuestions = result.totalQuestions
            correctAnswers = result.correctAnswers
            percentage = result.percentage
            timeSpent = result.timeSpent
        }
        
        func makeQuizResult() -> QuizResult {
            QuizResult(
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                percentage: percentage,
                timeSpent: timeSpent
            )
        }
    }
}

struct StartView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var model: StartViewModel
    
    init(model: StartViewModel) {
        _model = State(initialValue: model)
    }
    
    init(
        quizUseCase: QuizUseCaseProtocol,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        enhancedContainer: EnhancedDIContainer
    ) {
        let quizViewModel = QuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            settingsManager: settingsManager
        )
        _model = State(
            initialValue: StartViewModel(
                quizViewModel: quizViewModel,
                statsManager: statsManager,
                settingsManager: settingsManager,
                profileManager: profileManager,
                examUseCase: examUseCase,
                examStatisticsManager: examStatisticsManager,
                enhancedContainer: enhancedContainer
            )
        )
    }
    
    init(
        quizUseCase: QuizUseCaseProtocol,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager
    ) {
        let quizViewModel = QuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            settingsManager: settingsManager
        )
        _model = State(
            initialValue: StartViewModel(
                quizViewModel: quizViewModel,
                statsManager: statsManager,
                settingsManager: settingsManager,
                profileManager: profileManager,
                examUseCase: examUseCase,
                examStatisticsManager: examStatisticsManager,
                enhancedContainer: EnhancedDIContainer.shared
            )
        )
    }
    
    var body: some View {
        navigationContent(bindingModel: $model)
    }

    private func navigationContent(bindingModel: Binding<StartViewModel>) -> some View {
        let model = bindingModel.wrappedValue
        return NavigationStack(path: bindingModel.navigationPath) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection(model: model)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        summarySection(model: model)
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    .frame(minHeight: proxy.size.height, alignment: .bottom)
                }
                .scrollDisabled(false)
                .padding(.horizontal)
            }
            .navigationDestination(for: StartRoute.self) { route in
                @Bindable var quizViewModel = model.quizViewModel
                switch route {
                case .quiz:
                    QuizView(viewModel: quizViewModel)
                case .result(let snapshot):
                    ResultView(
                        result: snapshot.makeQuizResult(),
                        newAchievements: quizViewModel.newAchievements,
                        onPlayAgain: {
                            model.resetQuiz()
                            model.startQuiz()
                        },
                        onBackToStart: {
                            model.resetQuiz()
                        },
                        onAchievementsCleared: {
                            model.clearNewAchievements()
                        }
                    )
                case .stats:
                    StatsView(statsManager: model.statsManager)
                case .achievements:
                    AchievementsView()
                case .settings:
                    SettingsView(viewModel: SettingsViewModel(settingsManager: model.settingsManager))
                case .profile:
                    ProfileView()
                case .exam:
                    if let examViewModel = model.examViewModel {
                        ExamView(viewModel: examViewModel) {
                            model.finishExamSession()
                        }
                    }
                }
            }
            .sheet(isPresented: bindingModel.showingExamSettings) {
                ExamSettingsView { configuration in
                    model.startExam(with: configuration)
                }
                .environment(\.settingsManager, model.settingsManager)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            model.showStats()
                        }) {
                            Label("start.menu.stats".localized, systemImage: "chart.bar.fill")
                        }
                        
                        Button(action: {
                            model.showAchievements()
                        }) {
                            Label("start.menu.achievements".localized, systemImage: "trophy.fill")
                        }
                        
                        Button(action: {
                            model.showProfile()
                        }) {
                            Label("start.menu.profile".localized, systemImage: "person.crop.circle")
                        }
                        
                        Button(action: {
                            model.showSettings()
                        }) {
                            Label("start.menu.settings".localized, systemImage: "gearshape.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert(
                "error.title".localized,
                isPresented: Binding(
                    get: { model.quizViewModel.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            model.quizViewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("error.ok".localized) {
                    model.quizViewModel.errorMessage = nil
                }
            } message: {
                Text(model.quizViewModel.errorMessage ?? "")
            }
            .onAppear {
                model.onAppear()
            }
        }
        .onDisappear {
            model.onDisappear()
        }
        .onChange(of: model.settingsManager.settings.language) { _, _ in
            model.onLanguageChange()
        }
        .onChange(of: model.quizViewModel.state) { _, newValue in
            model.onQuizStateChange(newValue)
        }
    }
    
    // MARK: - Helper Functions
    private var adaptiveBorderColor: Color {
        switch colorScheme {
        case .light:
            return .black.opacity(0.2)
        case .dark:
            return .white.opacity(0.3)
        @unknown default:
            return .primary.opacity(0.2)
        }
    }
    
    // MARK: - View Sections
    private func heroSection(model: StartViewModel) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.2 * model.logoGlowIntensity), .purple.opacity(0.1 * model.logoGlowIntensity), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image("image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.4 * model.logoGlowIntensity), radius: 20, x: 0, y: 10)
                    .shadow(color: .purple.opacity(0.3 * model.logoGlowIntensity), radius: 30, x: 0, y: 0)
                
                TimelineView(.animation) { timeline in
                    ParticleFieldView(particles: model.particlesSnapshot(for: timeline.date))
                }
            }
            
            VStack(spacing: 8) {
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
        }
    }
    
    private func summarySection(model: StartViewModel) -> some View {
        VStack(spacing: 16) {
            statsCard(model: model)
            Divider()
                .background(adaptiveBorderColor)
            actionsSection(model: model)
        }
        .padding()
        .background(.regularMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(adaptiveBorderColor, lineWidth: 0.5)
        )
    }
    
    private func statsCard(model: StartViewModel) -> some View {
        Group {
            if model.statsManager.hasRecentGames() {
                VStack(spacing: 8) {
                    LocalizedText("start.averageScore")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(model.statsManager.getAverageRecentScore()))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("start.basedOnGames".localized(count: model.statsManager.getRecentGamesCount(), arguments: model.statsManager.getRecentGamesCount()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func actionsSection(model: StartViewModel) -> some View {
        VStack(spacing: 12) {
            quizButton(model: model)
            examButton(model: model)
        }
        .padding(.vertical, 12)
    }
    
    private func quizButton(model: StartViewModel) -> some View {
        Button(action: {
            model.startQuiz()
        }) {
            HStack(spacing: 12) {
                if model.quizViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                LocalizedText(model.quizViewModel.isLoading ? "start.loading" : "start.begin")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(model.quizViewModel.isLoading)
    }
    
    private func examButton(model: StartViewModel) -> some View {
        Button {
            model.showingExamSettings = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                LocalizedText("start.examMode")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func profileIconView(model: StartViewModel) -> some View {
        let profileManager = model.profileManager
        
        if profileManager.isSignedIn {
            if avatarExists(for: profileManager) {
                // Показываем аватар пользователя
                avatarImageView(for: profileManager)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 1.5)
                    )
            } else {
                // Показываем иконку с галочкой, если пользователь вошел, но нет аватара
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundColor(.blue)
            }
        } else {
            // Обычная иконка, если пользователь не вошел
            Image(systemName: "person.crop.circle")
                .foregroundColor(.blue)
        }
    }
    
    private func avatarExists(for profileManager: ProfileManager) -> Bool {
        guard let url = profileManager.profile.avatarURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    #if os(iOS)
    private func avatarImageView(for profileManager: ProfileManager) -> Image {
        guard let url = profileManager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let uiImage = UIImage(contentsOfFile: url.path) else {
            return Image(systemName: "person.crop.circle.fill")
        }
        return Image(uiImage: uiImage)
    }
    #else
    private func avatarImageView(for profileManager: ProfileManager) -> Image {
        guard let url = profileManager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data) else {
            return Image(systemName: "person.crop.circle.fill")
        }
        return Image(nsImage: nsImage)
    }
    #endif
}

private struct ParticleFieldView: View {
    let particles: [StartViewModel.Particle]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(.yellow.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .blur(radius: 1)
            }
        }
    }
}

#Preview {
    let statsManager = StatsManager()
    let settingsManager = SettingsManager()
    let examStatsManager = ExamStatisticsManager()
    let adaptiveEngine = AdaptiveLearningEngine()
    let profileManager = ProfileManager(
        adaptiveEngine: adaptiveEngine,
        statsManager: statsManager,
        examStatisticsManager: examStatsManager
    )
    let quizUseCase = QuizUseCase(
        questionsRepository: QuestionsRepository(),
        adaptiveEngine: adaptiveEngine,
        profileManager: profileManager
    )
    let examUseCase = ExamUseCase(
        questionsRepository: QuestionsRepository(),
        examStatisticsManager: examStatsManager
    )

    return StartView(
        quizUseCase: quizUseCase,
        statsManager: statsManager,
        settingsManager: settingsManager,
        profileManager: profileManager,
        examUseCase: examUseCase,
        examStatisticsManager: examStatsManager
    )
    .environment(\.settingsManager, settingsManager)
    .environment(\.statsManager, statsManager)
    .environment(\.profileManager, profileManager)
}

