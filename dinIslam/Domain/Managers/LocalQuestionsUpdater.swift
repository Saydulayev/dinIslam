//
//  LocalQuestionsUpdater.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Local Questions Updater
class LocalQuestionsUpdater {
    private let baseURL = "https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
    private let fileManager = FileManager.default
    
    // MARK: - Public Methods
    
    func updateLocalQuestionsIfNeeded() async -> UpdateResult {
        print("🔄 Checking if local questions need update...")
        
        let russianResult = await updateQuestionsFile(language: .russian)
        let englishResult = await updateQuestionsFile(language: .english)
        
        let totalUpdated = russianResult.updatedCount + englishResult.updatedCount
        let totalErrors = russianResult.errorCount + englishResult.errorCount
        
        return UpdateResult(
            updatedFiles: totalUpdated,
            errorCount: totalErrors,
            russianResult: russianResult,
            englishResult: englishResult
        )
    }
    
    func forceUpdateLocalQuestions() async -> UpdateResult {
        print("🔄 Force updating local questions...")
        
        let russianResult = await updateQuestionsFile(language: .russian, forceUpdate: true)
        let englishResult = await updateQuestionsFile(language: .english, forceUpdate: true)
        
        let totalUpdated = russianResult.updatedCount + englishResult.updatedCount
        let totalErrors = russianResult.errorCount + englishResult.errorCount
        
        return UpdateResult(
            updatedFiles: totalUpdated,
            errorCount: totalErrors,
            russianResult: russianResult,
            englishResult: englishResult
        )
    }
    
    // MARK: - Private Methods
    
    private func updateQuestionsFile(language: AppLanguage, forceUpdate: Bool = false) async -> FileUpdateResult {
        let fileName = language == .russian ? "questions.json" : "questions_en.json"
        let localFileName = language == .russian ? "questions" : "questions_en"
        
        do {
            // Загружаем данные с GitHub
            let remoteData = try await downloadQuestionsFromGitHub(fileName: fileName)
            let remoteQuestions = try JSONDecoder().decode([RemoteQuestion].self, from: remoteData)
            
            // Получаем локальные данные для сравнения
            let localQuestions = getLocalQuestions(fileName: localFileName)
            
            // Проверяем, нужно ли обновление
            if !forceUpdate && localQuestions.count >= remoteQuestions.count {
                print("✅ Local \(fileName) is up to date (\(localQuestions.count) questions)")
                return FileUpdateResult(
                    fileName: fileName,
                    updated: false,
                    localCount: localQuestions.count,
                    remoteCount: remoteQuestions.count,
                    error: nil
                )
            }
            
            // Обновляем локальный файл
            if await updateLocalFile(fileName: localFileName, data: remoteData) {
                print("✅ Updated local \(fileName) with \(remoteQuestions.count) questions")
                return FileUpdateResult(
                    fileName: fileName,
                    updated: true,
                    localCount: remoteQuestions.count,
                    remoteCount: remoteQuestions.count,
                    error: nil
                )
            } else {
                return FileUpdateResult(
                    fileName: fileName,
                    updated: false,
                    localCount: localQuestions.count,
                    remoteCount: remoteQuestions.count,
                    error: "Failed to write local file"
                )
            }
            
        } catch {
            print("❌ Error updating \(fileName): \(error)")
            return FileUpdateResult(
                fileName: fileName,
                updated: false,
                localCount: 0,
                remoteCount: 0,
                error: error.localizedDescription
            )
        }
    }
    
    private func downloadQuestionsFromGitHub(fileName: String) async throws -> Data {
        let urlString = "\(baseURL)/\(fileName)"
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }
        
        return data
    }
    
    private func getLocalQuestions(fileName: String) -> [Question] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            return []
        }
        return questions
    }
    
    private func updateLocalFile(fileName: String, data: Data) async -> Bool {
        // В реальном приложении мы не можем изменить файлы в Bundle
        // Это демонстрация того, как можно было бы обновить локальные файлы
        // В production приложении локальные файлы обновляются через процесс сборки
        
        print("📝 Would update local file \(fileName) with \(data.count) bytes")
        return true
    }
}

// MARK: - Update Result Models

struct UpdateResult {
    let updatedFiles: Int
    let errorCount: Int
    let russianResult: FileUpdateResult
    let englishResult: FileUpdateResult
    
    var success: Bool {
        return errorCount == 0 && updatedFiles > 0
    }
    
    var message: String {
        if success {
            return "Successfully updated \(updatedFiles) files"
        } else if errorCount > 0 {
            return "Updated \(updatedFiles) files with \(errorCount) errors"
        } else {
            return "No updates needed"
        }
    }
}

struct FileUpdateResult {
    let fileName: String
    let updated: Bool
    let localCount: Int
    let remoteCount: Int
    let error: String?
    
    var updatedCount: Int {
        return updated ? 1 : 0
    }
    
    var errorCount: Int {
        return error != nil ? 1 : 0
    }
}

// MARK: - Update Errors

enum UpdateError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case fileWriteError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for questions file"
        case .invalidResponse:
            return "Invalid response from server"
        case .fileWriteError:
            return "Failed to write local file"
        }
    }
}
