//
//  WidgetLink.swift
//  dinIslam
//
//  Ссылки, с которыми виджет открывает приложение. Файл входит и в виджет.
//

import Foundation

nonisolated enum WidgetLink {
    static let scheme = "dinislam"
    /// Повторение ошибок, срок которых наступил
    static let review = URL(string: "\(scheme)://review")!
}
