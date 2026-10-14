//
//  TopicStatsProviding.swift
//  dinIslam
//

import Foundation

/// Статистика ответов по темам: по ней адаптивный подбор находит слабые темы
protocol TopicStatsProviding {
    var topicStats: [String: TopicStat] { get }
}
