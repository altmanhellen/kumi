import Foundation

/// The study day starts at 04:00 local time so a midnight session isn't split in two.
enum StudyDay {
    static let startHour = 4
    private static let reference = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!

    static func of(_ date: Date, calendar: Calendar = .current) -> Int {
        let shifted = date.addingTimeInterval(-Double(startHour) * 3600)
        let start = calendar.startOfDay(for: shifted)
        return calendar.dateComponents([.day], from: reference, to: start).day ?? 0
    }

    static var today: Int { of(Date()) }

    /// Midday of a study day, for display.
    static func date(of day: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: day, to: reference)!.addingTimeInterval(12 * 3600)
    }

    static func relative(_ day: Int, from today: Int = StudyDay.today) -> String {
        let n = day - today
        switch n {
        case ..<1: return "сегодня"
        case 1: return "завтра"
        case 2: return "послезавтра"
        default: return "через \(n) \(Plural.days(n))"
        }
    }
}

enum Plural {
    static func form(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let m10 = n % 10, m100 = n % 100
        if m10 == 1 && m100 != 11 { return one }
        if (2...4).contains(m10) && !(12...14).contains(m100) { return few }
        return many
    }
    static func days(_ n: Int) -> String { form(n, "день", "дня", "дней") }
    static func cards(_ n: Int) -> String { form(n, "карточка", "карточки", "карточек") }
    static func expressions(_ n: Int) -> String { form(n, "выражение", "выражения", "выражений") }
    static func reviews(_ n: Int) -> String { form(n, "повторение", "повторения", "повторений") }
    static func minutes(_ n: Int) -> String { form(n, "минута", "минуты", "минут") }
}

enum TaskKind: String, Codable {
    case intro, recognition, production
}

/// One answer. The log is append-only and is the source of truth for progress.
struct ReviewLog: Codable, Identifiable, Hashable {
    let id: UUID
    let itemId: String
    let time: Date
    let kind: TaskKind
    let correct: Bool
    let usedHint: Bool
    let answerMs: Int
    /// nil means "no grade": intros, recognition, retries in the same session, extra practice.
    let rating: Rating?
    let sessionId: UUID
    let deviceId: String
    /// True when this production was a scheduled review (due that day).
    let scheduled: Bool
}

enum LearningState: String, Codable, CaseIterable {
    case new, learning, reviewing, mastered

    var title: String {
        switch self {
        case .new: "Новое"
        case .learning: "Изучается"
        case .reviewing: "Повторяется"
        case .mastered: "Освоено"
        }
    }

    /// Names used in the legend on the Progress tab.
    var progressTitle: String {
        switch self {
        case .new: "Осталось выучить"
        case .learning: "Начали учить"
        case .reviewing: "Повторяем"
        case .mastered: "Освоили"
        }
    }
}

/// Per-expression state, rebuilt by replaying the log.
struct CardState {
    var memory: MemoryState?
    var lastRatedDay: Int?
    var firstRatedDay: Int?
    var dueDay: Int?
    var reps = 0
    var lapses = 0
    var lastRating: Rating?
    var correctDays: Set<Int> = []
    var firstSeenDay: Int?
    var ratedDays: Set<Int> = []

    var state: LearningState {
        guard let lastRating, let first = firstRatedDay else { return .new }
        if lastRating == .again { return .learning }
        guard correctDays.contains(where: { $0 > first }) else { return .learning }
        if let s = memory?.stability, s >= 21, correctDays.count >= 2 { return .mastered }
        return .reviewing
    }

    func isDue(on day: Int) -> Bool {
        guard let dueDay, lastRating != nil else { return false }
        return dueDay <= day
    }

    func retrievability(on day: Int, fsrs: FSRS) -> Double {
        guard let memory, let last = lastRatedDay else { return 1 }
        return fsrs.retrievability(elapsedDays: Double(max(day - last, 0)), stability: memory.stability)
    }

    mutating func apply(_ log: ReviewLog, fsrs: FSRS) {
        let day = StudyDay.of(log.time)
        if firstSeenDay == nil { firstSeenDay = day }
        guard let rating = log.rating else { return }
        let elapsed = lastRatedDay.map { day - $0 } ?? 0
        memory = fsrs.next(state: memory, elapsedDays: elapsed, rating: rating)
        if firstRatedDay == nil { firstRatedDay = day }
        lastRatedDay = day
        ratedDays.insert(day)
        reps += 1
        lastRating = rating
        if rating == .again {
            lapses += 1
            dueDay = day + 1
        } else {
            correctDays.insert(day)
            let ivl = fsrs.fuzzed(fsrs.interval(stability: memory!.stability), seed: log.id.seed)
            dueDay = day + ivl
        }
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "Как в системе"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }
}

enum Accent: String, Codable, CaseIterable {
    case british, american
    var locale: String { self == .british ? "en-GB" : "en-US" }
}

struct Preferences: Codable, Equatable {
    var level: Level = .b1
    var topics: [String] = []
    var newPerDay = 10
    var reviewLimit = 50
    var showTranslation = true
    var accent: Accent = Locale.current.region?.identifier == "US" ? .american : .british
    var englishVoiceId: String?
    var russianVoiceId: String?
    var slowRate = 0.7
    var desiredRetention = 0.9
    var theme: AppTheme = .system
    var reminderEnabled = false
    var reminderHour = 19
    var reminderMinute = 0
    var onboarded = false
    var updatedAt = Date()
}

struct Account: Codable, Equatable {
    var userId: String
    var name: String?
    var email: String?
    var signedInAt: Date
}

struct ProgressFile: Codable {
    var formatVersion = 1
    var deviceId: String
    var logs: [ReviewLog]
    var prefs: Preferences
    var favorites: Set<String> = []
    var hidden: Set<String> = []
    var completedSessions = 0
    var account: Account?
}

/// Stores progress as JSON in Application Support, which iOS includes in the device backup.
enum ProgressStorage {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Kumi", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var progressURL: URL { directory.appendingPathComponent("progress.json") }
    static var sessionURL: URL { directory.appendingPathComponent("session.json") }

    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func load() -> ProgressFile? {
        guard let data = try? Data(contentsOf: progressURL) else { return nil }
        return try? decoder().decode(ProgressFile.self, from: data)
    }

    static func save(_ file: ProgressFile) {
        guard let data = try? encoder().encode(file) else { return }
        try? data.write(to: progressURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
