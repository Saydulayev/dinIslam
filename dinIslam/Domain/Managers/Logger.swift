//
//  Logger.swift
//  dinIslam
//
//  Created on 27.01.25.
//

import Foundation
import OSLog

/// Базовый логгер для приложения с использованием OSLog
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.dinIslam"
    
    // MARK: - Log Categories
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let general = Logger(subsystem: subsystem, category: "General")
    
    // MARK: - Convenience Methods
    
    /// Логирование информационного сообщения
    static func info(_ message: String, category: Logger = general) {
        category.info("\(message)")
    }
    
    /// Логирование предупреждения
    static func warning(_ message: String, category: Logger = general) {
        category.warning("\(message)")
    }
    
    /// Логирование ошибки
    static func error(_ message: String, error: Error? = nil, category: Logger = general) {
        if let err = error {
            category.error("\(message): \(err.localizedDescription)")
        } else {
            category.error("\(message)")
        }
    }
    
    /// Логирование ошибки с явным именем параметра для совместимости
    static func error(_ message: String, error err: Error, category: Logger = general) {
        category.error("\(message): \(err.localizedDescription)")
    }
    
    /// Логирование отладочного сообщения (только в DEBUG)
    static func debug(_ message: String, category: Logger = general) {
        #if DEBUG
        category.debug("\(message)")
        #endif
    }
}

