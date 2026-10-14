//
//  LocalSyncState.swift
//  dinIslam
//
//  Что устройство знает о синхронизации: свой идентификатор, поколения групп данных,
//  вклады других устройств из последнего снимка и ошибки на момент последней отправки.
//

import Foundation

struct LocalSyncState: Codable, Equatable {
    var deviceId: String
    /// Аккаунт iCloud последней успешной синхронизации; `nil` — устройство ещё не синхронизировалось
    var accountId: String?
    /// Номер последней отправки своего вклада
    var seq = 0
    var statsEpoch: SyncEpoch = .initial
    var achievementProgressEpoch: SyncEpoch = .initial
    var achievementsEpoch: SyncEpoch = .initial
    var questionPoolEpoch: SyncEpoch = .initial
    /// Вклады других устройств; локальные итоги = свой вклад + эти вклады
    var otherStatsDevices: [String: DeviceContribution<StatsCounters>] = [:]
    var otherAchievementDevices: [String: DeviceContribution<AchievementCounters>] = [:]
    /// Ошибки в iCloud после последней успешной отправки (база для трёхстороннего слияния)
    var reviewBase: [String: ReviewItem] = [:]

    init(deviceId: String = UUID().uuidString) {
        self.deviceId = deviceId
    }

    func epoch(of section: SyncSection) -> SyncEpoch {
        switch section {
        case .stats: return statsEpoch
        case .achievementProgress: return achievementProgressEpoch
        case .achievements: return achievementsEpoch
        case .questionPool: return questionPoolEpoch
        }
    }

    /// Новое поколение: данные других устройств этой группы больше не учитываются
    mutating func setEpoch(_ epoch: SyncEpoch, for section: SyncSection) {
        switch section {
        case .stats:
            guard statsEpoch != epoch else { return }
            statsEpoch = epoch
            otherStatsDevices = [:]
            reviewBase = [:]
        case .achievementProgress:
            guard achievementProgressEpoch != epoch else { return }
            achievementProgressEpoch = epoch
            otherAchievementDevices = [:]
        case .achievements:
            achievementsEpoch = epoch
        case .questionPool:
            questionPoolEpoch = epoch
        }
    }
}

extension LocalSyncState {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = container.decode(.deviceId, default: UUID().uuidString)
        accountId = container.decodeOptional(.accountId)
        seq = container.decode(.seq, default: 0)
        statsEpoch = container.decode(.statsEpoch, default: .initial)
        achievementProgressEpoch = container.decode(.achievementProgressEpoch, default: .initial)
        achievementsEpoch = container.decode(.achievementsEpoch, default: .initial)
        questionPoolEpoch = container.decode(.questionPoolEpoch, default: .initial)
        otherStatsDevices = container.decode(.otherStatsDevices, default: [:])
        otherAchievementDevices = container.decode(.otherAchievementDevices, default: [:])
        reviewBase = container.decode(.reviewBase, default: [:])
    }
}

/// Хранит состояние синхронизации в UserDefaults
final class LocalSyncStateStore {
    private let userDefaults: UserDefaults
    private let key = "SyncState"

    private(set) var state: LocalSyncState

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        state = userDefaults.decodeStored(LocalSyncState.self, forKey: key) ?? LocalSyncState()
        save()
    }

    func update(_ change: (inout LocalSyncState) -> Void) {
        change(&state)
        save()
    }

    /// Новое поколение для групп, сброшенных на этом устройстве
    func startNewEpoch(for sections: [SyncSection], at date: Date = Date()) {
        update { state in
            for section in sections {
                state.setEpoch(.new(at: date), for: section)
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: key)
        }
    }
}
