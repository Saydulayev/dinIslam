//
//  ExamResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct ExamResultView: View {
    let result: ExamResult
    let viewModel: ExamViewModel
    let onRetake: () -> Void
    let onBackToMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetailedStats = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                ExamResultHeaderView(result: result)
                
                // Grade and score
                ExamGradeView(result: result)
                
                // Statistics cards
                ExamStatsCardsView(result: result)
                
                // Detailed breakdown
                ExamBreakdownView(result: result)
                
                // Action buttons
                ExamResultActionsView(
                    viewModel: viewModel,
                    onRetake: onRetake,
                    onBackToMenu: onBackToMenu
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("exam.result.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Exam Result Header
struct ExamResultHeaderView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: result.isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(result.isPassed ? .green : .red)
            
            // Title
            Text(result.isPassed ? "exam.result.passed".localized : "exam.result.failed".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Score - показываем процент от общего количества вопросов
            Text("\(Int(result.percentage))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(result.isPassed ? .green : .red)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Exam Grade View
struct ExamGradeView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text("exam.result.grade".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(result.grade.localizedName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(gradeColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(gradeColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gradeColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var gradeColor: Color {
        switch result.grade {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .satisfactory:
            return .orange
        case .unsatisfactory:
            return .red
        }
    }
}

// MARK: - Exam Stats Cards
struct ExamStatsCardsView: View {
    let result: ExamResult
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ExamStatCard(
                title: "exam.result.answered".localized,
                value: "\(result.answeredQuestions)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
            
            ExamStatCard(
                title: "exam.result.correct".localized,
                value: "\(result.correctAnswers)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            ExamStatCard(
                title: "exam.result.incorrect".localized,
                value: "\(result.incorrectAnswers)",
                icon: "xmark.circle.fill",
                color: .red
            )
            
            ExamStatCard(
                title: "exam.result.skipped".localized,
                value: "\(result.skippedQuestions)",
                icon: "forward.fill",
                color: .orange
            )
        }
    }
}

// MARK: - Exam Stat Card
struct ExamStatCard: View {
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
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Exam Breakdown View
struct ExamBreakdownView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("exam.result.breakdown".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ExamBreakdownRow(
                    title: "exam.result.totalQuestions".localized,
                    value: "\(result.totalQuestions)",
                    color: .primary
                )
                
                ExamBreakdownRow(
                    title: "exam.result.timeSpent".localized,
                    value: formatTime(result.totalTimeSpent),
                    color: .blue
                )
                
                ExamBreakdownRow(
                    title: "exam.result.averageTime".localized,
                    value: formatTime(result.averageTimePerQuestion),
                    color: .green
                )
                
                ExamBreakdownRow(
                    title: "exam.result.timeExpired".localized,
                    value: "\(result.timeExpiredQuestions)",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exam Breakdown Row
struct ExamBreakdownRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Exam Result Actions
struct ExamResultActionsView: View {
    let viewModel: ExamViewModel
    let onRetake: () -> Void
    let onBackToMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Retake exam button
            Button(action: onRetake) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("exam.result.retake".localized)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 16))
            }
            
            Button(action: onBackToMenu) {
                HStack {
                    Image(systemName: "house.fill")
                    LocalizedText("result.backToStart")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        ExamResultView(
            result: ExamResult(
                totalQuestions: 20,
                answeredQuestions: 18,
                skippedQuestions: 2,
                correctAnswers: 16,
                incorrectAnswers: 2,
                timeExpiredQuestions: 1,
                totalTimeSpent: 600,
                averageTimePerQuestion: 30,
                percentage: 88.9,
                configuration: .default,
                completedAt: Date()
            ),
            viewModel: ExamViewModel(
                examUseCase: ExamUseCase(
                    questionsRepository: QuestionsRepository(),
                    examStatisticsManager: ExamStatisticsManager()
                ),
                examStatisticsManager: ExamStatisticsManager(),
                settingsManager: SettingsManager()
            ),
            onRetake: {},
            onBackToMenu: {}
        )
    }
}
