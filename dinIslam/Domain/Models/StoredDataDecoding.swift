//
//  StoredDataDecoding.swift
//  dinIslam
//
//  Чтение сохранённых данных пользователя без потерь при изменении формата.
//  Синтезированный Decodable падает на отсутствующем ключе, и тогда пропадает весь объект:
//  статистика, ошибки, серия. Поэтому сохраняемые модели читают каждое поле отдельно,
//  с значением по умолчанию, а массивы — поэлементно.
//

import Foundation
import OSLog

extension KeyedDecodingContainer {
    /// Значение по ключу; если ключа нет или значение не читается (другой тип,
    /// неизвестное значение перечисления) — `defaultValue`.
    func decode<T: Decodable>(_ key: Key, default defaultValue: @autoclosure () -> T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? defaultValue()
    }

    /// Необязательное значение: отсутствующее или нечитаемое становится nil.
    func decodeOptional<T: Decodable>(_ key: Key) -> T? {
        (try? decodeIfPresent(T.self, forKey: key)) ?? nil
    }

    /// Массив, из которого выбрасываются только нечитаемые элементы, а не весь массив.
    func decodeLossyArray<T: Codable>(_ key: Key, default defaultValue: @autoclosure () -> [T] = []) -> [T] {
        guard let items = try? decodeIfPresent([LossyDecodable<T>].self, forKey: key) else {
            return defaultValue()
        }
        return items.compactMap(\.value)
    }
}

extension UserDefaults {
    /// Читает JSON по ключу. Если данные есть, но не читаются, они копируются
    /// в `<key>.unreadable` (один раз), чтобы следующее сохранение не стёрло их бесследно.
    func decodeStored<T: Decodable>(_ type: T.Type, forKey key: String, decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            AppLogger.error("Failed to read stored \(key)", error: error, category: AppLogger.data)
            let backupKey = key + ".unreadable"
            if object(forKey: backupKey) == nil {
                set(data, forKey: backupKey)
            }
            return nil
        }
    }
}
