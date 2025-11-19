//
//  ExamSettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct ExamSettingsView: View {
    @State private var selectedConfiguration: ExamConfiguration = .default
    @State private var customTimePerQuestion: Double = 30
    @State private var customTotalQuestions: Int = 20
    @State private var allowSkip: Bool = true
    @State private var showTimer: Bool = true
    @State private var autoSubmit: Bool = true
    @State private var isCustomMode: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settingsManager) private var settingsManager
    
    let onStartExam: (ExamConfiguration) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignTokens.Colors.background1,
                        DesignTokens.Colors.background2
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                            // Preset configurations
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                Text("exam.settings.presets".localized)
                                    .font(DesignTokens.Typography.h2)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                                
                                VStack(spacing: DesignTokens.Spacing.sm) {
                                    ForEach(ExamPreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                                        ExamPresetRow(
                                            preset: preset,
                                            isSelected: selectedConfiguration == preset.configuration && !isCustomMode,
                                            onTap: {
                                                selectedConfiguration = preset.configuration
                                                isCustomMode = false
                                            }
                                        )
                                    }
                                    
                                    // Custom configuration
                                    ExamPresetRow(
                                        preset: .custom,
                                        isSelected: isCustomMode,
                                        onTap: {
                                            isCustomMode = true
                                            // Инициализируем пользовательские параметры значениями по умолчанию
                                            customTimePerQuestion = 30
                                            customTotalQuestions = 20
                                            allowSkip = true
                                            showTimer = true
                                            autoSubmit = true
                                        }
                                    )
                                }
                                .padding(DesignTokens.Spacing.xxl)
                                .cardStyle(
                                    cornerRadius: DesignTokens.CornerRadius.xlarge,
                                    fillColor: DesignTokens.Colors.cardBackground,
                                    borderColor: DesignTokens.Colors.iconOrange.opacity(0.3),
                                    shadowColor: Color.black.opacity(0.2),
                                    shadowRadius: 8,
                                    shadowYOffset: 4
                                )
                                .padding(.horizontal, DesignTokens.Spacing.xxl)
                                
                                Text("exam.settings.presets.footer".localized)
                                    .font(DesignTokens.Typography.label)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                            }
                    
                            // Custom settings
                            if isCustomMode {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                    Text("exam.settings.custom".localized)
                                        .font(DesignTokens.Typography.h2)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                                    
                                    VStack(spacing: DesignTokens.Spacing.xl) {
                                        // Time per question
                                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                            HStack {
                                                Text("exam.settings.timePerQuestion".localized)
                                                    .font(DesignTokens.Typography.bodyRegular)
                                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                                Spacer()
                                                Text("\(Int(customTimePerQuestion)) сек")
                                                    .font(DesignTokens.Typography.secondarySemibold)
                                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                                            }
                                            
                                            Slider(value: $customTimePerQuestion, in: 10...120, step: 5)
                                                .tint(DesignTokens.Colors.iconBlue)
                                        }
                                        
                                        Divider()
                                            .background(DesignTokens.Colors.borderSubtle)
                                        
                                        // Total questions
                                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                            HStack {
                                                Text("exam.settings.totalQuestions".localized)
                                                    .font(DesignTokens.Typography.bodyRegular)
                                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                                Spacer()
                                                Text("\(customTotalQuestions)")
                                                    .font(DesignTokens.Typography.secondarySemibold)
                                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                                            }
                                            
                                            Slider(value: Binding(
                                                get: { Double(customTotalQuestions) },
                                                set: { customTotalQuestions = Int($0) }
                                            ), in: 5...50, step: 1)
                                            .tint(DesignTokens.Colors.iconBlue)
                                        }
                                        
                                        Divider()
                                            .background(DesignTokens.Colors.borderSubtle)
                                        
                                        // Additional options
                                        VStack(spacing: DesignTokens.Spacing.md) {
                                            HStack {
                                                Image(systemName: "forward.fill")
                                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                                    .foregroundColor(DesignTokens.Colors.iconOrange)
                                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                                
                                                Text("exam.settings.allowSkip".localized)
                                                    .font(DesignTokens.Typography.bodyRegular)
                                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                                
                                                Spacer()
                                                
                                                Toggle("", isOn: $allowSkip)
                                                    .tint(DesignTokens.Colors.iconBlue)
                                            }
                                            
                                            HStack {
                                                Image(systemName: "timer")
                                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                                
                                                Text("exam.settings.showTimer".localized)
                                                    .font(DesignTokens.Typography.bodyRegular)
                                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                                
                                                Spacer()
                                                
                                                Toggle("", isOn: $showTimer)
                                                    .tint(DesignTokens.Colors.iconBlue)
                                            }
                                            
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                                    .foregroundColor(DesignTokens.Colors.statusGreen)
                                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                                
                                                Text("exam.settings.autoSubmit".localized)
                                                    .font(DesignTokens.Typography.bodyRegular)
                                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                                
                                                Spacer()
                                                
                                                Toggle("", isOn: $autoSubmit)
                                                    .tint(DesignTokens.Colors.iconBlue)
                                            }
                                        }
                                    }
                                    .padding(DesignTokens.Spacing.xxl)
                                    .cardStyle(
                                    cornerRadius: DesignTokens.CornerRadius.xlarge,
                                    fillColor: DesignTokens.Colors.cardBackground,
                                    borderColor: DesignTokens.Colors.iconOrange.opacity(0.3),
                                    shadowColor: Color.black.opacity(0.2),
                                    shadowRadius: 8,
                                    shadowYOffset: 4
                                )
                                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                                    
                                    Text("exam.settings.custom.footer".localized)
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                                }
                            }
                    
                            // Preview
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                Text("exam.settings.preview".localized)
                                    .font(DesignTokens.Typography.h2)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                                
                                ExamPreviewCard(configuration: currentConfiguration)
                                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                            }
                        }
                        .padding(.top, DesignTokens.Spacing.lg)
                        .padding(.bottom, DesignTokens.Spacing.xxxl)
                    }
                    
                    // Start Exam Button
                    VStack(spacing: 0) {
                        Divider()
                            .background(DesignTokens.Colors.borderSubtle)
                        
                        Button(action: startExam) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                LocalizedText("exam.settings.start")
                                    .font(DesignTokens.Typography.secondarySemibold)
                            }
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .cardStyle(
                                cornerRadius: DesignTokens.CornerRadius.medium,
                                fillColor: DesignTokens.Colors.iconBlue.opacity(0.15),
                                borderColor: DesignTokens.Colors.iconBlue.opacity(0.35),
                                shadowColor: Color.black.opacity(0.2),
                                shadowRadius: 8,
                                shadowYOffset: 4
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                    .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .background(DesignTokens.Colors.cardBackground)
                    }
                }
            }
            .navigationTitle("exam.settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("exam.settings.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
        }
    }
    
    private var currentConfiguration: ExamConfiguration {
        if isCustomMode {
            return ExamConfiguration(
                timePerQuestion: customTimePerQuestion,
                totalQuestions: customTotalQuestions,
                allowSkip: allowSkip,
                showTimer: showTimer,
                autoSubmit: autoSubmit
            )
        } else {
            return selectedConfiguration
        }
    }
    
    private func startExam() {
        onStartExam(currentConfiguration)
        dismiss()
    }
}

// MARK: - Exam Preset
enum ExamPreset: CaseIterable {
    case quick
    case standard
    case extended
    case custom
    
    var configuration: ExamConfiguration {
        switch self {
        case .quick:
            return ExamConfiguration(
                timePerQuestion: 15,
                totalQuestions: 10,
                allowSkip: false,
                showTimer: true,
                autoSubmit: true
            )
        case .standard:
            return ExamConfiguration.default
        case .extended:
            return ExamConfiguration(
                timePerQuestion: 60,
                totalQuestions: 30,
                allowSkip: true,
                showTimer: true,
                autoSubmit: true
            )
        case .custom:
            return ExamConfiguration.default
        }
    }
    
    var title: String {
        switch self {
        case .quick:
            return "exam.preset.quick".localized
        case .standard:
            return "exam.preset.standard".localized
        case .extended:
            return "exam.preset.extended".localized
        case .custom:
            return "exam.preset.custom".localized
        }
    }
    
    var description: String {
        switch self {
        case .quick:
            return "exam.preset.quick.description".localized
        case .standard:
            return "exam.preset.standard.description".localized
        case .extended:
            return "exam.preset.extended.description".localized
        case .custom:
            return "exam.preset.custom.description".localized
        }
    }
    
    var icon: String {
        switch self {
        case .quick:
            return "bolt.fill"
        case .standard:
            return "clock.fill"
        case .extended:
            return "clock.badge.checkmark"
        case .custom:
            return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .quick:
            return DesignTokens.Colors.iconOrange
        case .standard:
            return DesignTokens.Colors.iconBlue
        case .extended:
            return DesignTokens.Colors.iconPurple
        case .custom:
            return DesignTokens.Colors.statusGreen
        }
    }
}

// MARK: - Exam Preset Row
struct ExamPresetRow: View {
    let preset: ExamPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // Icon
                Image(systemName: preset.icon)
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundColor(preset.color)
                    .frame(width: DesignTokens.Sizes.iconLarge)
                
                // Content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(preset.title)
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(preset.description)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.iconBlue)
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exam Preview Card
struct ExamPreviewCard: View {
    let configuration: ExamConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("exam.settings.preview.title".localized)
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("exam.settings.preview.questions".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text("\(configuration.totalQuestions)")
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                HStack {
                    Text("exam.settings.preview.timePerQuestion".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text("\(Int(configuration.timePerQuestion)) сек")
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                HStack {
                    Text("exam.settings.preview.totalTime".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text(formatTotalTime())
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                HStack {
                    Text("exam.settings.preview.options".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text(optionsText())
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundColor(DesignTokens.Colors.iconBlue)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(
            cornerRadius: DesignTokens.CornerRadius.large,
            fillColor: DesignTokens.Colors.cardBackground,
            borderColor: DesignTokens.Colors.iconOrange.opacity(0.3),
            shadowColor: Color.black.opacity(0.2),
            shadowRadius: 8,
            shadowYOffset: 4
        )
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = Int(configuration.timePerQuestion * Double(configuration.totalQuestions))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func optionsText() -> String {
        var options: [String] = []
        
        if configuration.allowSkip {
            options.append("exam.settings.preview.skip".localized)
        }
        if configuration.showTimer {
            options.append("exam.settings.preview.timer".localized)
        }
        if configuration.autoSubmit {
            options.append("exam.settings.preview.autoSubmit".localized)
        }
        
        return options.joined(separator: ", ")
    }
}

#Preview {
    ExamSettingsView { _ in }
        .environment(\.settingsManager, SettingsManager())
}
