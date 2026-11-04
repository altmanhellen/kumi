import Foundation

struct SessionStep: Codable, Identifiable, Equatable {
    var id = UUID()
    let itemId: String
    let kind: TaskKind
    /// A production for an expression whose review was due.
    var review = false
    /// A repeat after a mistake in this session: never graded.
    var retry = false
}

enum SessionSource: Codable, Equatable {
    case today, onboarding, extra
    case learn(String)
    case practice(String)

    var isPractice: Bool { if case .practice = self { return true } else { return false } }
}

struct SessionEntry: Codable, Equatable {
    var isReview = false
    var isNew = false
    var mistakes = 0
    var answered = false
    var firstTryCorrect: Bool?
}

struct SessionState: Codable, Equatable {
    var id = UUID()
    var source: SessionSource
    var steps: [SessionStep]
    var index = 0
    var studyDay: Int
    var startedAt = Date()
    var draft = ""
    var hintShown = false
    var translationShown = false
    var stepStartedAt = Date()
    var entries: [String: SessionEntry] = [:]
    /// Order in which expressions first appeared, for the summary.
    var order: [String] = []

    var current: SessionStep? { index < steps.count ? steps[index] : nil }
    var progress: Double { steps.isEmpty ? 0 : Double(index) / Double(steps.count) }
}

struct SummaryRow: Identifiable, Equatable {
    var id: String { itemId }
    let itemId: String
    let phrase: String
    let note: String
    let next: String
}

struct SessionSummary: Equatable {
    let source: SessionSource
    let reviews: Int
    let newStarted: Int
    let fixedMistakes: Int
    let rows: [SummaryRow]
    let tomorrowDue: Int
}

extension AppModel {
    // MARK: Building

    /// New expressions go in groups of three: intro and recognition for each, then their productions.
    /// That puts every production 2–4 steps after the expression was shown.
    static func steps(reviews: [String], news: [String]) -> [SessionStep] {
        var steps = reviews.map { SessionStep(itemId: $0, kind: .production, review: true) }
        var i = 0
        while i < news.count {
            let batch = Array(news[i..<min(i + 3, news.count)])
            for id in batch {
                steps.append(SessionStep(itemId: id, kind: .intro))
                steps.append(SessionStep(itemId: id, kind: .recognition))
            }
            for id in batch { steps.append(SessionStep(itemId: id, kind: .production)) }
            i += 3
        }
        return steps
    }

    func startSession(source: SessionSource, reviews: [String], news: [String]) {
        var state = SessionState(source: source, steps: Self.steps(reviews: reviews, news: news), studyDay: today)
        for id in reviews { state.entries[id] = SessionEntry(isReview: true) }
        for id in news { state.entries[id] = SessionEntry(isNew: true) }
        guard !state.steps.isEmpty else { return }
        lastSummary = nil
        session = state
        showingSession = true
        persistSession()
    }

    func startToday() {
        let p = plan
        startSession(source: .today, reviews: p.reviews, news: p.news)
    }

    func startExtraNew(_ count: Int = 5) {
        startSession(source: .extra, reviews: [], news: Array(eligibleNewIds().prefix(count)))
    }

    /// "Учить тему": new expressions from a group, counted against the same daily limit.
    func startLearning(title: String, ids: [String]) {
        let fresh = ids.filter { card($0).firstSeenDay == nil && !isHidden($0) }
        let due = Set(dueIds())
        startSession(source: .learn(title), reviews: ids.filter { due.contains($0) }, news: Array(fresh.prefix(max(prefs.newPerDay, 5))))
    }

    /// "Потренироваться": started expressions; only those due today are graded.
    func startPractice(title: String, ids: [String]) {
        let started = ids.filter { card($0).lastRating != nil && !isHidden($0) }.shuffled()
        let due = Set(dueIds())
        var state = SessionState(
            source: .practice(title),
            steps: started.prefix(15).map { SessionStep(itemId: $0, kind: .production, review: due.contains($0)) },
            studyDay: today
        )
        for id in started.prefix(15) { state.entries[id] = SessionEntry(isReview: due.contains(id)) }
        guard !state.steps.isEmpty else { return }
        lastSummary = nil
        session = state
        showingSession = true
        persistSession()
    }

    func remainingNewToday() -> Int { max(prefs.newPerDay - startedTodayIds.count, 0) }

    // MARK: Answers

    private func log(_ step: SessionStep, kind: TaskKind, correct: Bool, hint: Bool = false, rating: Rating?, scheduled: Bool) {
        guard let s = session else { return }
        let ms = Int(Date().timeIntervalSince(s.stepStartedAt) * 1000)
        record(ReviewLog(
            id: UUID(), itemId: step.itemId, time: Date(), kind: kind, correct: correct, usedHint: hint,
            answerMs: min(ms, 120_000), rating: rating, sessionId: s.id, deviceId: file.deviceId, scheduled: scheduled
        ))
    }

    private func noteSeen(_ id: String) {
        guard var s = session else { return }
        if !s.order.contains(id) { s.order.append(id) }
        session = s
    }

    func answerIntro(alreadyKnown: Bool) {
        guard var s = session, let step = s.current else { return }
        noteSeen(step.itemId)
        log(step, kind: .intro, correct: true, rating: nil, scheduled: false)
        s = session!
        if alreadyKnown {
            // Skip recognition and go straight to recall.
            if let r = s.steps.indices.first(where: { $0 > s.index && s.steps[$0].itemId == step.itemId && s.steps[$0].kind == .recognition }) {
                s.steps.remove(at: r)
            }
            if let p = s.steps.indices.first(where: { $0 > s.index && s.steps[$0].itemId == step.itemId && s.steps[$0].kind == .production }) {
                let prod = s.steps.remove(at: p)
                s.steps.insert(prod, at: s.index + 1)
            }
        }
        session = s
        advance()
    }

    func answerRecognition(_ option: String) -> Bool {
        guard let step = session?.current, let item = library[step.itemId] else { return false }
        noteSeen(step.itemId)
        let correct = option == item.phrase
        log(step, kind: .recognition, correct: correct, rating: nil, scheduled: false)
        return correct
    }

    /// Checks a typed answer, writes it to the log and requeues the expression after a mistake.
    func answerProduction(_ input: String, gaveUp: Bool = false) -> CheckResult {
        guard var s = session, let step = s.current, let item = library[step.itemId] else {
            return CheckResult(verdict: .wrong, target: "", marks: [])
        }
        noteSeen(step.itemId)
        s = session!
        let result = gaveUp
            ? CheckResult(verdict: .wrong, target: AnswerChecker.normalize(item.gap.answer), marks: [])
            : AnswerChecker.check(input, gap: item.gap, level: item.level)
        let correct = result.verdict.isCorrect
        let c = card(item.id)
        let due = c.isDue(on: today)
        let isNew = c.lastRating == nil
        let graded = !step.retry && !c.ratedDays.contains(today) && (due || (isNew && !s.source.isPractice))
        var rating: Rating?
        if graded {
            if !correct { rating = .again }
            else if s.hintShown || result.verdict == .typoAccepted { rating = .hard }
            else { rating = .good }
        }
        log(step, kind: .production, correct: correct, hint: s.hintShown, rating: rating, scheduled: due)

        var entry = s.entries[item.id] ?? SessionEntry()
        if !entry.answered {
            entry.answered = true
            entry.firstTryCorrect = correct
        }
        if !correct {
            entry.mistakes += 1
            if entry.mistakes == 1 {
                let at = min(s.index + 4, s.steps.count)
                s.steps.insert(SessionStep(itemId: item.id, kind: .production, retry: true), at: at)
            } else if entry.mistakes == 2 {
                s.steps.append(SessionStep(itemId: item.id, kind: .recognition, retry: true))
                s.steps.append(SessionStep(itemId: item.id, kind: .production, retry: true))
            }
        }
        s.entries[item.id] = entry
        session = s
        persistSession()
        return result
    }

    func setDraft(_ text: String) {
        guard session != nil else { return }
        session!.draft = text
        persistSession()
    }

    func showHint() {
        session?.hintShown = true
        persistSession()
    }

    func showTranslation() {
        session?.translationShown = true
        persistSession()
    }

    func advance() {
        guard var s = session else { return }
        s.index += 1
        s.draft = ""
        s.hintShown = false
        s.translationShown = false
        s.stepStartedAt = Date()
        session = s
        if s.index >= s.steps.count {
            finishSession(s, abandoned: false)
        } else {
            persistSession()
        }
    }

    /// Closing early keeps every answer: undone steps simply return to the plan.
    func closeSession() {
        if let s = session { finishSession(s, abandoned: true) }
        lastSummary = nil
        showingSession = false
    }

    func finishSession(_ s: SessionState, abandoned: Bool) {
        lastSummary = summary(for: s)
        if !abandoned { markSessionCompleted() }
        session = nil
        persistSession()
    }

    func dismissSummary() {
        lastSummary = nil
        showingSession = false
    }

    func summary(for s: SessionState) -> SessionSummary {
        var rows: [SummaryRow] = []
        for id in s.order {
            guard let item = library[id], let e = s.entries[id] else { continue }
            let c = card(id)
            let note: String
            if !e.answered { note = "познакомились" }
            else if e.mistakes == 0 { note = "вспомнили сразу" }
            else if e.firstTryCorrect == false && e.mistakes < 3 { note = "ошибка → исправили в конце" }
            else { note = "были ошибки, вернёмся завтра" }
            let next = c.dueDay.map { StudyDay.relative($0, from: today) } ?? "в следующий раз"
            rows.append(SummaryRow(itemId: id, phrase: item.phrase, note: note, next: next))
        }
        rows.sort { ($0.note == "вспомнили сразу" ? 1 : 0) < ($1.note == "вспомнили сразу" ? 1 : 0) }
        let tomorrow = library.items.filter { card($0.id).isDue(on: today + 1) }.count
        return SessionSummary(
            source: s.source,
            reviews: s.entries.values.filter { $0.isReview && $0.answered }.count,
            newStarted: s.order.filter { s.entries[$0]?.isNew == true }.count,
            fixedMistakes: s.entries.values.filter { $0.mistakes > 0 }.count,
            rows: rows,
            tomorrowDue: tomorrow
        )
    }
}
