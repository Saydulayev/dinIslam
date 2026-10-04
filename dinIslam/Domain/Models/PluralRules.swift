//
//  PluralRules.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

/// Выбор ключа формы множественного числа: `key` (1), `key_2` (2–4), `key_5` (5–20) для русского,
/// `key` / `key_other` для английского. Язык берётся у основного LocalizationProviding,
/// поэтому формы переключаются вместе с остальным интерфейсом
enum PluralRules {
    static func key(for key: String, count: Int, language: String) -> String {
        switch language {
        case AppLanguage.russian.rawValue:
            return russianKey(for: key, count: count)
        default:
            return englishKey(for: key, count: count)
        }
    }
    
    private static func russianKey(for key: String, count: Int) -> String {
        let absCount = abs(count)
        let lastDigit = absCount % 10
        let lastTwoDigits = absCount % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "\(key)_5" // 11-19 use plural form
        } else if lastDigit == 1 {
            return key // 1, 21, 31, etc. use singular
        } else if lastDigit >= 2 && lastDigit <= 4 {
            return "\(key)_2" // 2-4, 22-24, etc. use few form
        } else {
            return "\(key)_5" // 0, 5-9, 10, 20, etc. use plural form
        }
    }
    
    private static func englishKey(for key: String, count: Int) -> String {
        abs(count) == 1 ? key : "\(key)_other"
    }
}
