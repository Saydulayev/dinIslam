//
//  StatsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var statsManager: StatsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)
                        
                        Text(LocalizationManager.shared.localizedString(for: "stats.title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.questionsStudied"),
                            value: "\(statsManager.stats.totalQuestionsStudied)",
                            icon: "questionmark.circle.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.correctAnswers"),
                            value: "\(statsManager.stats.correctAnswers)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.incorrectAnswers"),
                            value: "\(statsManager.stats.incorrectAnswers)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                        
                        StatCard(
                            title: LocalizationManager.shared.localizedString(for: "stats.accuracy"),
                            value: String(format: "%.1f%%", statsManager.stats.accuracyPercentage),
                            icon: "target",
                            color: .orange
                        )
                    }
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationManager.shared.localizedString(for: "stats.progress"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ProgressRow(
                                title: LocalizationManager.shared.localizedString(for: "stats.quizzesCompleted"),
                                value: statsManager.stats.totalQuizzesCompleted,
                                color: .blue
                            )
                            
                            if let lastQuiz = statsManager.stats.lastQuizDate {
                                HStack {
                                    Text(LocalizationManager.shared.localizedString(for: "stats.lastQuiz"))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(lastQuiz, style: .date)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizationManager.shared.localizedString(for: "stats.wrongQuestions"))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text(LocalizationManager.shared.localizedString(for: "stats.wrongQuestionsCount"))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(statsManager.stats.wrongQuestionsCount)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: {
                                    // TODO: Start review mode
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text(LocalizationManager.shared.localizedString(for: "stats.repeatMistakes"))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "stats.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ProgressRow: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    StatsView(statsManager: StatsManager())
}
