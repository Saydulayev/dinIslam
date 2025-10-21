//
//  StatsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct StatsView: View {
    var statsManager: StatsManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var mistakesViewModel: QuizViewModel?
    @State private var showingMistakesReview = false
    @State private var totalQuestionsCount: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - компактный
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: geometry.size.height < 700 ? 40 : 50))
                        .foregroundStyle(.blue.gradient)
                    
                    Text(LocalizationManager.shared.localizedString(for: "stats.title"))
                        .font(geometry.size.height < 700 ? .title2 : .largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Основной контент
                VStack(spacing: 20) {
                    // Stats Cards - адаптивная сетка
                    let cardSpacing: CGFloat = geometry.size.height < 700 ? 16 : 20
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: cardSpacing) {
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.questionsStudied"),
                            value: "\(statsManager.stats.totalQuestionsStudied)",
                            icon: "questionmark.circle.fill",
                            color: .blue,
                            isCompact: geometry.size.height < 700
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.correctAnswers"),
                            value: "\(statsManager.stats.correctAnswers)",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            isCompact: geometry.size.height < 700
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.incorrectAnswers"),
                            value: "\(statsManager.stats.incorrectAnswers)",
                            icon: "xmark.circle.fill",
                            color: .red,
                            isCompact: geometry.size.height < 700
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.correctedMistakes"),
                            value: "\(statsManager.stats.correctedMistakes)",
                            icon: "checkmark.circle.badge.xmark",
                            color: .orange,
                            isCompact: geometry.size.height < 700
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.totalQuestions"),
                            value: "\(totalQuestionsCount)",
                            icon: "book.fill",
                            color: .purple,
                            isCompact: geometry.size.height < 700
                        )
                    }
                    
                    // Progress Section - увеличенная
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationManager.shared.localizedString(for: "stats.progress"))
                            .font(geometry.size.height < 700 ? .title3 : .title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 10) {
                            ProgressRow(
                                title: LocalizationManager.shared.localizedString(for: "stats.quizzesCompleted"),
                                value: statsManager.stats.totalQuizzesCompleted,
                                color: .blue,
                                isCompact: geometry.size.height < 700
                            )
                            
                            if let lastQuiz = statsManager.stats.lastQuizDate {
                                HStack {
                                    Text(LocalizationManager.shared.localizedString(for: "stats.lastQuiz"))
                                        .font(geometry.size.height < 700 ? .caption : .subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(lastQuiz, style: .date)
                                        .font(geometry.size.height < 700 ? .caption : .subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(geometry.size.height < 700 ? 16 : 20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Wrong Questions Section - увеличенная
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localizedString(for: "stats.wrongQuestions"))
                                .font(geometry.size.height < 700 ? .title3 : .title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text(LocalizationManager.shared.localizedString(for: "stats.wrongQuestionsCount"))
                                        .font(geometry.size.height < 700 ? .subheadline : .body)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(statsManager.stats.wrongQuestionsCount)")
                                        .font(geometry.size.height < 700 ? .subheadline : .body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: {
                                    startMistakesReview()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(geometry.size.height < 700 ? .subheadline : .body)
                                        Text(LocalizationManager.shared.localizedString(for: "stats.repeatMistakes"))
                                            .font(geometry.size.height < 700 ? .subheadline : .body)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.size.height < 700 ? 44 : 50)
                                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(geometry.size.height < 700 ? 16 : 20)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "stats.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "stats.done")) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingMistakesReview) {
                if let viewModel = mistakesViewModel {
                    MistakesReviewNavigationView(viewModel: viewModel)
                }
            }
            .onAppear {
                loadTotalQuestionsCount()
            }
    }
    
    private func loadTotalQuestionsCount() {
        Task {
            do {
                let questionsRepository = QuestionsRepository()
                let currentLanguage = settingsManager.settings.language.rawValue
                let questions = try await questionsRepository.loadQuestions(language: currentLanguage)
                
                await MainActor.run {
                    totalQuestionsCount = questions.count
                    print("📊 StatsView: Loaded \(questions.count) total questions")
                }
            } catch {
                print("❌ StatsView: Failed to load questions count: \(error)")
                await MainActor.run {
                    totalQuestionsCount = 0
                }
            }
        }
    }
    
    private func startMistakesReview() {
        print("DEBUG: Starting mistakes review...")
        print("DEBUG: Wrong questions count: \(statsManager.stats.wrongQuestionIds.count)")
        
        let quizUseCase = QuizUseCase(questionsRepository: QuestionsRepository())
        let viewModel = QuizViewModel(quizUseCase: quizUseCase, statsManager: statsManager, settingsManager: settingsManager)
        
        mistakesViewModel = viewModel
        showingMistakesReview = true
        
        Task {
            print("DEBUG: Starting async mistakes review...")
            await viewModel.startMistakesReview()
            print("DEBUG: Mistakes review completed. State: \(viewModel.state)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: isCompact ? 10 : 16) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 24 : 32))
                .foregroundColor(color)
            
            Text(value)
                .font(isCompact ? .title2 : .largeTitle)
                .fontWeight(.bold)
            
            Text(title)
                .font(isCompact ? .caption : .subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(isCompact ? 16 : 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: isCompact ? 16 : 20))
    }
}

struct ProgressRow: View {
    let title: String
    let value: Int
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(isCompact ? .subheadline : .body)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(isCompact ? .subheadline : .body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    StatsView(statsManager: StatsManager())
}

