//
//  MistakesResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesResultView: View {
    let result: QuizResult
    let onRepeat: () -> Void
    let onBackToStart: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Result icon
            VStack(spacing: 16) {
                Image(systemName: resultIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(resultColor.gradient)
                
                LocalizedText("mistakes.result.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            // Score details
            VStack(spacing: 20) {
                // Main score
                VStack(spacing: 8) {
                    Text("\(Int(result.percentage))%")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(resultColor)
                    
                    LocalizedText("mistakes.result.correctAnswers")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Detailed stats
                VStack(spacing: 12) {
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.totalQuestions"),
                        value: "\(result.totalQuestions)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.correctAnswers"),
                        value: "\(result.correctAnswers)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.timeSpent"),
                        value: formatTime(result.timeSpent)
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Improvement badge
            if result.percentage >= 70 {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    LocalizedText("mistakes.result.improvement")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else if result.percentage < 50 {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.orange)
                    LocalizedText("mistakes.result.needMorePractice")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: onRepeat) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        LocalizedText("mistakes.result.repeatAgain")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: onBackToStart) {
                    HStack {
                        Image(systemName: "house.fill")
                        LocalizedText("mistakes.result.backToStart")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private var resultIcon: String {
        switch result.percentage {
        case 80...:
            return "checkmark.circle.fill"
        case 60..<80:
            return "arrow.up.circle.fill"
        case 40..<60:
            return "arrow.down.circle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var resultColor: Color {
        switch result.percentage {
        case 80...:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    let result = QuizResult(totalQuestions: 10, correctAnswers: 7, percentage: 70, timeSpent: 80)
    MistakesResultView(result: result, onRepeat: {}, onBackToStart: {})
}
