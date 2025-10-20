//
//  StartView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct StartView: View {
    @State private var viewModel: QuizViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showingSettings = false
    @AppStorage("bestScore") private var bestScore: Double = 0
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App Title
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Tabiin Academy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    LocalizedText("start.description")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Best Score
                if bestScore > 0 {
                    VStack(spacing: 8) {
                        LocalizedText("start.bestScore")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(bestScore))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Start Button
                Button(action: {
                    Task {
                        await viewModel.startQuiz()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        
                        LocalizedText(viewModel.isLoading ? "start.loading" : "start.begin")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.state == .playing },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.restartQuiz()
                        }
                    }
                )
            ) {
                QuizView(viewModel: viewModel)
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.state == .finished },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.restartQuiz()
                        }
                    }
                )
            ) {
                ResultView(viewModel: viewModel, bestScore: $bestScore)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: SettingsViewModel(settingsManager: settingsManager))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert(LocalizationManager.shared.localizedString(for: "error.title"),
                   isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(LocalizationManager.shared.localizedString(for: "error.ok")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    StartView(viewModel: QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository())))
        .environmentObject(SettingsManager())
}
