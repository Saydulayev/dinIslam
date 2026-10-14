//
//  SyncSnapshot.swift
//  dinIslam
//
//  Полный снимок данных, который синхронизируется через iCloud: статистика, ошибки и их
//  расписание, серия дней, экзамены, достижения, пройденные вопросы банка, имя и фото.
//  Правила слияния — в SyncMerger.swift.
//

import Foundation

// MARK: - Sections

/// Группы данных, которые сбрасываются по отдельности
enum SyncSection: String, CaseIterable, Codable {
    /// Ответы, темы, сложности, ошибки и повторения, серия дней, экзамены
    case stats
    /// Счётчики для достижений: изучено вопросов, пройдено викторин, идеальные результаты, серия побед
    case achievementProgress
    /// Открытые достижения
    case achievements
    /// Пройденные вопросы банка
    case questionPool
}

/// Поколение группы данных. Сброс создаёт новое поколение; при синхронизации данные
/// более нового поколения заменяют данные старого на всех устройствах.
struct SyncEpoch: Codable, Equatable {
    var id: String
    var date: Date

    static let initial = SyncEpoch(id: "initial", date: .distantPast)

    static func new(at date: Date = Date()) -> SyncEpoch {
        SyncEpoch(id: UUID().uuidString, date: date)
    }

    func isNewer(than other: SyncEpoch) -> Bool {
        date != other.date ? date > other.date : id > other.id
    }
}

/// Значение, побеждающее по времени изменения
struct Timestamped<Value: Codable & Equatable>: Codable, Equatable {
    var value: Value
    var updatedAt: Date
}

extension Date {
    /// Время изменения имени и фото — целые секунды (профиль на диске хранит даты без долей секунды).
    /// Округление вверх: изменение не оказывается раньше предыдущего в ту же секунду
    static var syncTimestamp: Date {
        Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.up))
    }
}

// MARK: - Counters

/// Счётчики, которые только растут в пределах поколения. Каждое устройство пишет в снимок
/// только свой вклад, итог — сумма вкладов: ответы с двух устройств складываются, а не теряются.
protocol SyncCounters: Codable, Equatable {
    static var zero: Self { get }
    static func + (lhs: Self, rhs: Self) -> Self
    /// Разность не уходит ниже нуля
    static func - (lhs: Self, rhs: Self) -> Self
}

struct AnswerCounter: Codable, Equatable {
    var correct = 0
    var total = 0
}

struct StatsCounters: SyncCounters {
    var correctAnswers = 0
    var incorrectAnswers = 0
    var correctedMistakes = 0
    var topics: [String: AnswerCounter] = [:]
    var difficulties: [String: AnswerCounter] = [:]
    var examsCompleted = 0
    var examsPassed = 0
    var examsFailed = 0
    var examQuestionsAnswered = 0
    var examCorrectAnswers = 0
    var examTimeSpent: Double = 0

    static let zero = StatsCounters()

    static func + (lhs: StatsCounters, rhs: StatsCounters) -> StatsCounters {
        StatsCounters(
            correctAnswers: lhs.correctAnswers + rhs.correctAnswers,
            incorrectAnswers: lhs.incorrectAnswers + rhs.incorrectAnswers,
            correctedMistakes: lhs.correctedMistakes + rhs.correctedMistakes,
            topics: combine(lhs.topics, rhs.topics, +),
            difficulties: combine(lhs.difficulties, rhs.difficulties, +),
            examsCompleted: lhs.examsCompleted + rhs.examsCompleted,
            examsPassed: lhs.examsPassed + rhs.examsPassed,
            examsFailed: lhs.examsFailed + rhs.examsFailed,
            examQuestionsAnswered: lhs.examQuestionsAnswered + rhs.examQuestionsAnswered,
            examCorrectAnswers: lhs.examCorrectAnswers + rhs.examCorrectAnswers,
            examTimeSpent: lhs.examTimeSpent + rhs.examTimeSpent
        )
    }

    static func - (lhs: StatsCounters, rhs: StatsCounters) -> StatsCounters {
        StatsCounters(
            correctAnswers: max(0, lhs.correctAnswers - rhs.correctAnswers),
            incorrectAnswers: max(0, lhs.incorrectAnswers - rhs.incorrectAnswers),
            correctedMistakes: max(0, lhs.correctedMistakes - rhs.correctedMistakes),
            topics: combine(lhs.topics, rhs.topics, -).filter { $0.value.total > 0 },
            difficulties: combine(lhs.difficulties, rhs.difficulties, -).filter { $0.value.total > 0 },
            examsCompleted: max(0, lhs.examsCompleted - rhs.examsCompleted),
            examsPassed: max(0, lhs.examsPassed - rhs.examsPassed),
            examsFailed: max(0, lhs.examsFailed - rhs.examsFailed),
            examQuestionsAnswered: max(0, lhs.examQuestionsAnswered - rhs.examQuestionsAnswered),
            examCorrectAnswers: max(0, lhs.examCorrectAnswers - rhs.examCorrectAnswers),
            examTimeSpent: max(0, lhs.examTimeSpent - rhs.examTimeSpent)
        )
    }

    private static func combine(
        _ lhs: [String: AnswerCounter],
        _ rhs: [String: AnswerCounter],
        _ operation: (Int, Int) -> Int
    ) -> [String: AnswerCounter] {
        var result: [String: AnswerCounter] = [:]
        for key in Set(lhs.keys).union(rhs.keys) {
            let left = lhs[key] ?? AnswerCounter()
            let right = rhs[key] ?? AnswerCounter()
            result[key] = AnswerCounter(
                correct: max(0, operation(left.correct, right.correct)),
                total: max(0, operation(left.total, right.total))
            )
        }
        return result
    }
}

struct AchievementCounters: SyncCounters {
    var questionsStudied = 0
    var quizzesCompleted = 0
    var perfectScores = 0

    static let zero = AchievementCounters()

    static func + (lhs: AchievementCounters, rhs: AchievementCounters) -> AchievementCounters {
        AchievementCounters(
            questionsStudied: lhs.questionsStudied + rhs.questionsStudied,
            quizzesCompleted: lhs.quizzesCompleted + rhs.quizzesCompleted,
            perfectScores: lhs.perfectScores + rhs.perfectScores
        )
    }

    static func - (lhs: AchievementCounters, rhs: AchievementCounters) -> AchievementCounters {
        AchievementCounters(
            questionsStudied: max(0, lhs.questionsStudied - rhs.questionsStudied),
            quizzesCompleted: max(0, lhs.quizzesCompleted - rhs.quizzesCompleted),
            perfectScores: max(0, lhs.perfectScores - rhs.perfectScores)
        )
    }
}

/// Вклад одного устройства. `seq` растёт с каждой отправкой: из двух копий вклада новее та, у которой он больше.
struct DeviceContribution<Counters: SyncCounters>: Codable, Equatable {
    var seq: Int
    var counters: Counters
}

extension Dictionary {
    func total<Counters: SyncCounters>(excluding deviceId: String? = nil) -> Counters
    where Key == String, Value == DeviceContribution<Counters> {
        reduce(Counters.zero) { sum, entry in
            entry.key == deviceId ? sum : sum + entry.value.counters
        }
    }
}

// MARK: - Section Values

struct LastQuiz: Codable, Equatable {
    var date: Date
    var percentage: Double
}

struct TopicStreak: Codable, Equatable {
    var streak: Int
    var longestStreak: Int
    var lastUpdated: Date?
}

struct ExamSummary: Codable, Equatable {
    var lastExamDate: Date?
    var bestScore: Double = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
}

struct WinStreak: Codable, Equatable {
    var current: Int = 0
    var longest: Int = 0
    /// Дата последней викторины, после которой серия известна
    var updatedAt: Date = .distantPast
}

struct StatsSection: Codable, Equatable {
    var epoch: SyncEpoch = .initial
    var devices: [String: DeviceContribution<StatsCounters>] = [:]
    var lastQuiz: LastQuiz?
    var recentQuizResults: [QuizResultRecord] = []
    var topicStreaks: [String: TopicStreak] = [:]
    /// Ошибки и их расписание повторений: ключ — id вопроса
    var reviewItems: [String: ReviewItem] = [:]
    var dailyProgress = DailyProgress()
    var exam = ExamSummary()
}

struct AchievementProgressSection: Codable, Equatable {
    var epoch: SyncEpoch = .initial
    var devices: [String: DeviceContribution<AchievementCounters>] = [:]
    var winStreak = WinStreak()
}

struct AchievementsSection: Codable, Equatable {
    var epoch: SyncEpoch = .initial
    /// Открытые достижения: id → дата открытия
    var unlocked: [String: Date] = [:]
}

struct QuestionPoolSection: Codable, Equatable {
    var epoch: SyncEpoch = .initial
    var usedIds: Set<String> = []
}

// MARK: - Snapshot

struct SyncSnapshot: Codable, Equatable {
    /// Версия формата: снимок более новой версии приложение не перезаписывает
    static let currentFormat = 1

    var format = SyncSnapshot.currentFormat
    var displayName = Timestamped<String?>(value: nil, updatedAt: .distantPast)
    /// Отпечаток фото (`""` — фото нет); само фото хранится в записи CloudKit отдельно
    var avatar = Timestamped<String>(value: "", updatedAt: .distantPast)
    var stats = StatsSection()
    var achievementProgress = AchievementProgressSection()
    var achievements = AchievementsSection()
    var questionPool = QuestionPoolSection()

    /// Даты кодируются без округления: после пересылки снимок совпадает с исходным,
    /// иначе одни и те же результаты и времена изменений выглядели бы разными
    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) throws -> SyncSnapshot {
        try JSONDecoder().decode(SyncSnapshot.self, from: data)
    }

    func epoch(of section: SyncSection) -> SyncEpoch {
        switch section {
        case .stats: return stats.epoch
        case .achievementProgress: return achievementProgress.epoch
        case .achievements: return achievements.epoch
        case .questionPool: return questionPool.epoch
        }
    }
}

// MARK: - Decoding
// Снимок пишут разные версии приложения: отсутствующее поле получает значение по умолчанию
// (см. StoredDataDecoding.swift), а не делает нечитаемым весь снимок.

extension SyncEpoch {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decode(.id, default: SyncEpoch.initial.id)
        date = container.decode(.date, default: SyncEpoch.initial.date)
    }
}

extension AnswerCounter {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        correct = container.decode(.correct, default: 0)
        total = container.decode(.total, default: 0)
    }
}

extension StatsCounters {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        incorrectAnswers = container.decode(.incorrectAnswers, default: 0)
        correctedMistakes = container.decode(.correctedMistakes, default: 0)
        topics = container.decode(.topics, default: [:])
        difficulties = container.decode(.difficulties, default: [:])
        examsCompleted = container.decode(.examsCompleted, default: 0)
        examsPassed = container.decode(.examsPassed, default: 0)
        examsFailed = container.decode(.examsFailed, default: 0)
        examQuestionsAnswered = container.decode(.examQuestionsAnswered, default: 0)
        examCorrectAnswers = container.decode(.examCorrectAnswers, default: 0)
        examTimeSpent = container.decode(.examTimeSpent, default: 0)
    }
}

extension AchievementCounters {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionsStudied = container.decode(.questionsStudied, default: 0)
        quizzesCompleted = container.decode(.quizzesCompleted, default: 0)
        perfectScores = container.decode(.perfectScores, default: 0)
    }
}

extension TopicStreak {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        streak = container.decode(.streak, default: 0)
        longestStreak = container.decode(.longestStreak, default: 0)
        lastUpdated = container.decodeOptional(.lastUpdated)
    }
}

extension ExamSummary {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastExamDate = container.decodeOptional(.lastExamDate)
        bestScore = container.decode(.bestScore, default: 0)
        currentStreak = container.decode(.currentStreak, default: 0)
        longestStreak = container.decode(.longestStreak, default: 0)
    }
}

extension WinStreak {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        current = container.decode(.current, default: 0)
        longest = container.decode(.longest, default: 0)
        updatedAt = container.decode(.updatedAt, default: .distantPast)
    }
}

extension StatsSection {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        epoch = container.decode(.epoch, default: .initial)
        devices = container.decode(.devices, default: [:])
        lastQuiz = container.decodeOptional(.lastQuiz)
        recentQuizResults = container.decodeLossyArray(.recentQuizResults)
        topicStreaks = container.decode(.topicStreaks, default: [:])
        reviewItems = container.decode(.reviewItems, default: [:])
        dailyProgress = container.decode(.dailyProgress, default: DailyProgress())
        exam = container.decode(.exam, default: ExamSummary())
    }
}

extension AchievementProgressSection {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        epoch = container.decode(.epoch, default: .initial)
        devices = container.decode(.devices, default: [:])
        winStreak = container.decode(.winStreak, default: WinStreak())
    }
}

extension AchievementsSection {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        epoch = container.decode(.epoch, default: .initial)
        unlocked = container.decode(.unlocked, default: [:])
    }
}

extension QuestionPoolSection {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        epoch = container.decode(.epoch, default: .initial)
        usedIds = container.decode(.usedIds, default: [])
    }
}

extension SyncSnapshot {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        format = container.decode(.format, default: 1)
        displayName = container.decode(.displayName, default: Timestamped(value: nil, updatedAt: .distantPast))
        avatar = container.decode(.avatar, default: Timestamped(value: "", updatedAt: .distantPast))
        stats = container.decode(.stats, default: StatsSection())
        achievementProgress = container.decode(.achievementProgress, default: AchievementProgressSection())
        achievements = container.decode(.achievements, default: AchievementsSection())
        questionPool = container.decode(.questionPool, default: QuestionPoolSection())
    }
}
