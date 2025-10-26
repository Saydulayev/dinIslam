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
    @EnvironmentObject private var settingsManager: SettingsManager
    
    let onStartExam: (ExamConfiguration) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                // Preset configurations
                Section {
                    ForEach(ExamPreset.allCases, id: \.self) { preset in
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
                        }
                    )
                } header: {
                    Text("exam.settings.presets".localized)
                } footer: {
                    Text("exam.settings.presets.footer".localized)
                }
                
                // Custom settings
                if isCustomMode {
                    Section {
                        // Time per question
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("exam.settings.timePerQuestion".localized)
                                    .font(.body)
                                Spacer()
                                Text("\(Int(customTimePerQuestion)) сек")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: $customTimePerQuestion, in: 10...120, step: 5)
                                .accentColor(.blue)
                        }
                        .padding(.vertical, 4)
                        
                        // Total questions
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("exam.settings.totalQuestions".localized)
                                    .font(.body)
                                Spacer()
                                Text("\(customTotalQuestions)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: Binding(
                                get: { Double(customTotalQuestions) },
                                set: { customTotalQuestions = Int($0) }
                            ), in: 5...50, step: 1)
                            .accentColor(.blue)
                        }
                        .padding(.vertical, 4)
                        
                        // Additional options
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "forward.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                Text("exam.settings.allowSkip".localized)
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: $allowSkip)
                            }
                            
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("exam.settings.showTimer".localized)
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: $showTimer)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                
                                Text("exam.settings.autoSubmit".localized)
                                    .font(.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: $autoSubmit)
                            }
                        }
                    } header: {
                        Text("exam.settings.custom".localized)
                    } footer: {
                        Text("exam.settings.custom.footer".localized)
                    }
                }
                
                // Preview
                Section {
                    ExamPreviewCard(configuration: currentConfiguration)
                } header: {
                    Text("exam.settings.preview".localized)
                }
            }
            .navigationTitle("exam.settings.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("exam.settings.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("exam.settings.start".localized) {
                        startExam()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
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
            return "hourglass.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .quick:
            return .orange
        case .standard:
            return .blue
        case .extended:
            return .purple
        case .custom:
            return .green
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
            HStack(spacing: 16) {
                // Icon
                Image(systemName: preset.icon)
                    .font(.title2)
                    .foregroundColor(preset.color)
                    .frame(width: 32)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(preset.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exam Preview Card
struct ExamPreviewCard: View {
    let configuration: ExamConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("exam.settings.preview.title".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("exam.settings.preview.questions".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(configuration.totalQuestions)")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("exam.settings.preview.timePerQuestion".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(configuration.timePerQuestion)) сек")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("exam.settings.preview.totalTime".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTotalTime())
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("exam.settings.preview.options".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(optionsText())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        .environmentObject(SettingsManager())
}
