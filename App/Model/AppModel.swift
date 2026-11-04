import Foundation
import Observation
import SwiftUI

struct DailyPlan: Equatable {
    var reviews: [String]
    var news: [String]
    /// Everything due today, before the review limit.
    var dueTotal: Int
    var startedToday: Int
    var newLimit: Int
    /// New expressions still available on the user's level.
    var eligibleNew: Int
    var catchingUp: Bool
    var levelFinished: Bool

    var total: Int { reviews.count + news.count }
    var isEmpty: Bool { total == 0 }

    /// Why the number of new cards is what it is.
    var newReason: String {
        if catchingUp { return "Сегодня догоняем повторения: новых не будет, остаток перейдёт на следующее занятие без штрафа." }
        if levelFinished { return "Новые выражения вашего уровня закончились." }
        let left = max(newLimit - startedToday, 0)
        if news.count < left {
            return "Новых — не больше \(newLimit) в день. На вашем уровне осталось \(eligibleNew) \(Plural.expressions(eligibleNew))."
        }
        if startedToday > 0 {
            return "Новых — не больше \(newLimit) в день, \(startedToday) вы уже начали сегодня."
        }
        return "Новых — не больше \(newLimit) в день."
    }
}

@MainActor
@Observable
final class AppModel {
    let library: ContentLibrary
    private(set) var file: ProgressFile
    private(set) var cards: [String: CardState] = [:]
    private(set) var today = StudyDay.today
    var session: SessionState?
    var showingSession = false
    var lastSummary: SessionSummary?
    /// Becomes true after the second finished session, when it is time to ask about reminders.
    var shouldOfferReminder = false
    /// A catalog screen to open when the Catalog tab appears (set from Today).
    var pendingCatalog: CatalogFilter?

    var prefs: Preferences { file.prefs }
    var fsrs: FSRS { FSRS(desiredRetention: file.prefs.desiredRetention) }
    var logs: [ReviewLog] { file.logs }

    init(library: ContentLibrary = .loadBundled()) {
        self.library = library
        if let saved = ProgressStorage.load() {
            file = saved
        } else {
            file = ProgressFile(deviceId: UUID().uuidString, logs: [], prefs: Preferences())
        }
        rebuildCards()
        restoreSession()
    }

    // MARK: Cards

    func rebuildCards() {
        var result: [String: CardState] = [:]
        let f = fsrs
        for log in file.logs.sorted(by: { $0.time < $1.time }) {
            result[log.itemId, default: CardState()].apply(log, fsrs: f)
        }
        cards = result
    }

    private func rebuildCard(_ id: String) {
        var card = CardState()
        let f = fsrs
        for log in file.logs where log.itemId == id { card.apply(log, fsrs: f) }
        cards[id] = card
    }

    func card(_ id: String) -> CardState { cards[id] ?? CardState() }
    func state(_ id: String) -> LearningState { card(id).state }
    func isFavorite(_ id: String) -> Bool { file.favorites.contains(id) }
    func isHidden(_ id: String) -> Bool { file.hidden.contains(id) }

    func refreshDay() {
        let now = StudyDay.today
        if now != today {
            today = now
            if let s = session, s.studyDay != now { finishSession(s, abandoned: true) }
        }
    }

    // MARK: Plan

    func dueIds(on day: Int? = nil) -> [String] {
        let d = day ?? today
        let f = fsrs
        return library.items
            .filter { !isHidden($0.id) && card($0.id).isDue(on: d) }
            .sorted { card($0.id).retrievability(on: d, fsrs: f) < card($1.id).retrievability(on: d, fsrs: f) }
            .map(\.id)
    }

    /// Expressions first seen today, in the order they were introduced.
    var startedTodayIds: [String] {
        var seen = Set<String>(), result: [String] = []
        for log in file.logs where StudyDay.of(log.time) == today && cards[log.itemId]?.firstSeenDay == today {
            if seen.insert(log.itemId).inserted { result.append(log.itemId) }
        }
        return result
    }

    /// New expressions on the user's level, chosen topics first.
    func eligibleNewIds(level: Level? = nil) -> [String] {
        let lvl = level ?? prefs.level
        let chosen = Set(prefs.topics)
        let pool = library.items.filter { $0.level == lvl && !isHidden($0.id) && card($0.id).firstSeenDay == nil }
        let preferred = pool.filter { !chosen.isDisjoint(with: $0.topics) }
        let rest = pool.filter { chosen.isDisjoint(with: $0.topics) }
        return (preferred + rest).map(\.id)
    }

    var plan: DailyPlan {
        let due = dueIds()
        let reviews = Array(due.prefix(prefs.reviewLimit))
        let started = startedTodayIds.count
        let eligible = eligibleNewIds()
        let catchingUp = due.count > prefs.reviewLimit
        let newCount = catchingUp ? 0 : min(max(prefs.newPerDay - started, 0), eligible.count)
        return DailyPlan(
            reviews: reviews, news: Array(eligible.prefix(newCount)), dueTotal: due.count,
            startedToday: started, newLimit: prefs.newPerDay, eligibleNew: eligible.count,
            catchingUp: catchingUp, levelFinished: eligible.isEmpty
        )
    }

    /// Minutes, from the user's own average answer times when there is history.
    func estimateMinutes(reviews: Int, news: Int) -> Int {
        let productions = file.logs.suffix(300).filter { $0.kind == .production && $0.answerMs > 0 }
        let reviewSec = productions.isEmpty ? 20 : Double(productions.map(\.answerMs).reduce(0, +)) / Double(productions.count) / 1000 + 6
        let total = Double(reviews) * reviewSec + Double(news) * 60
        return max(1, Int((total / 60).rounded()))
    }

    var expressionOfTheDay: Collocation {
        let pool = library.items.filter { $0.level <= prefs.level }
        let list = pool.isEmpty ? library.items : pool
        var rng = SplitMix64(seed: UInt64(today) &* 2654435761)
        return list[Int(rng.next() % UInt64(list.count))]
    }

    /// The most recently studied topic that still has new phrases on the user's level.
    var continueTopic: String? {
        var seen = Set<String>()
        for log in file.logs.reversed() {
            guard let item = library[log.itemId] else { continue }
            for topic in item.topics where !seen.contains(topic) {
                seen.insert(topic)
                let hasNew = library.items.contains {
                    $0.topics.contains(topic) && $0.level == prefs.level && card($0.id).firstSeenDay == nil && !isHidden($0.id)
                }
                if hasNew { return topic }
            }
        }
        return nil
    }

    /// What was done today: graded reviews, new expressions started and minutes spent.
    var todayStats: (reviews: Int, news: Int, minutes: Int) {
        let todays = file.logs.filter { StudyDay.of($0.time) == today }
        let reviews = Set(todays.filter { $0.scheduled && $0.kind == .production }.map(\.itemId)).count
        let ms = todays.map(\.answerMs).reduce(0, +)
        return (reviews, startedTodayIds.count, max(1, Int((Double(ms) / 60000).rounded())))
    }

    // MARK: Counters

    func counts(for ids: [String]) -> [LearningState: Int] {
        var result: [LearningState: Int] = [:]
        for id in ids { result[state(id), default: 0] += 1 }
        return result
    }

    var studiedDays: Set<Int> { Set(file.logs.map { StudyDay.of($0.time) }) }

    /// Share of first attempts on scheduled reviews in the last 30 days that were right.
    var firstAttemptAccuracy: Double? {
        let from = today - 30
        let rated = file.logs.filter { $0.scheduled && $0.rating != nil && StudyDay.of($0.time) > from }
        guard rated.count >= 3 else { return nil }
        return Double(rated.filter(\.correct).count) / Double(rated.count)
    }

    // MARK: Preferences

    func updatePrefs(_ change: (inout Preferences) -> Void) {
        let retention = file.prefs.desiredRetention
        change(&file.prefs)
        file.prefs.updatedAt = Date()
        if file.prefs.desiredRetention != retention { rebuildCards() }
        save()
    }

    func toggleFavorite(_ id: String) {
        if file.favorites.contains(id) { file.favorites.remove(id) } else { file.favorites.insert(id) }
        save()
    }

    func toggleHidden(_ id: String) {
        if file.hidden.contains(id) { file.hidden.remove(id) } else { file.hidden.insert(id) }
        save()
    }

    func setAccount(_ account: Account?) {
        file.account = account
        save()
    }

    // MARK: Log

    func record(_ log: ReviewLog) {
        file.logs.append(log)
        rebuildCard(log.itemId)
        save()
    }

    func save() { ProgressStorage.save(file) }

    // MARK: Export / import

    func exportJSON() throws -> URL {
        let data = try ProgressStorage.encoder().encode(file)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("word-partners-progress-\(Self.stamp()).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    func exportCSV() throws -> URL {
        var rows = ["id,phrase,level,group,state,next_review,favorite"]
        for item in library.items {
            let c = card(item.id)
            let next = c.dueDay.map { Self.isoDay(StudyDay.date(of: $0)) } ?? ""
            let phrase = item.phrase.replacingOccurrences(of: "\"", with: "\"\"")
            rows.append("\(item.id),\"\(phrase)\",\(item.level.rawValue),\"\(item.structureSet)\",\(c.state.rawValue),\(next),\(isFavorite(item.id) ? 1 : 0)")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("word-partners-expressions-\(Self.stamp()).csv")
        try rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Merges records by UUID and never deletes anything. Returns how many answers were added.
    @discardableResult
    func importProgress(from url: URL) throws -> Int {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let other = try ProgressStorage.decoder().decode(ProgressFile.self, from: data)
        let known = Set(file.logs.map(\.id))
        let added = other.logs.filter { !known.contains($0.id) }
        file.logs.append(contentsOf: added)
        file.favorites.formUnion(other.favorites)
        file.hidden.formUnion(other.hidden)
        if other.prefs.updatedAt > file.prefs.updatedAt || !file.prefs.onboarded {
            file.prefs = other.prefs
            file.prefs.onboarded = true
        }
        file.completedSessions = max(file.completedSessions, other.completedSessions)
        rebuildCards()
        save()
        return added.count
    }

    func resetProgress() {
        file.logs = []
        file.favorites = []
        file.hidden = []
        file.completedSessions = 0
        session = nil
        try? FileManager.default.removeItem(at: ProgressStorage.sessionURL)
        rebuildCards()
        save()
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f.string(from: Date())
    }

    private static func isoDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    // MARK: Session persistence

    func persistSession() {
        guard let session else {
            try? FileManager.default.removeItem(at: ProgressStorage.sessionURL)
            return
        }
        if let data = try? ProgressStorage.encoder().encode(session) {
            try? data.write(to: ProgressStorage.sessionURL, options: .atomic)
        }
    }

    private func restoreSession() {
        guard let data = try? Data(contentsOf: ProgressStorage.sessionURL),
              let saved = try? ProgressStorage.decoder().decode(SessionState.self, from: data) else { return }
        if saved.studyDay == today, saved.index < saved.steps.count {
            session = saved
            showingSession = true
        } else {
            try? FileManager.default.removeItem(at: ProgressStorage.sessionURL)
        }
    }

    func markSessionCompleted() {
        file.completedSessions += 1
        if file.completedSessions == 2 && !prefs.reminderEnabled { shouldOfferReminder = true }
        save()
    }
}
