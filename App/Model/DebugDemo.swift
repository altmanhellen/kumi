#if DEBUG
import Foundation

/// Launch arguments for checking screens in the simulator. Not part of release builds.
/// -wpDemo seeds two weeks of answers, -wpTab catalog|progress, -wpSession, -wpStep N.
extension AppModel {
    func applyDebugArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ key: String) -> String? {
            guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if args.contains("-wpDemo") && file.logs.isEmpty {
            updatePrefs { $0.onboarded = true; $0.level = .b1; $0.topics = ["Работа и карьера", "Путешествия"] }
            let ids = library.items.filter { $0.level == .a2 || $0.structureSet == "Make" }.prefix(40).map(\.id)
            var rng = SplitMix64(seed: 3)
            for (n, id) in ids.enumerated() {
                var day = today - 20 + n % 14
                for _ in 0..<(1 + Int(rng.next() % 5)) {
                    guard day < today else { break }
                    let ok = rng.next() % 5 != 0
                    record(ReviewLog(id: UUID(), itemId: id, time: StudyDay.date(of: day), kind: .production, correct: ok,
                                     usedHint: false, answerMs: 9000, rating: ok ? .good : .again, sessionId: UUID(),
                                     deviceId: file.deviceId, scheduled: true))
                    day = card(id).dueDay ?? day + 1
                }
            }
        }
        if args.contains("-wpFresh") && !prefs.onboarded {
            updatePrefs { $0.onboarded = true; $0.level = .c1; $0.topics = ["Общество и новости"] }
        }
        if (args.contains("-wpSession") || args.contains("-wpDone")) && session == nil {
            startToday()
            let skip = args.contains("-wpDone") ? 10_000 : (Int(value("-wpStep") ?? "0") ?? 0)
            for _ in 0..<skip {
                guard let step = session?.current else { break }
                switch step.kind {
                case .intro: answerIntro(alreadyKnown: false)
                case .recognition: _ = answerRecognition(library[step.itemId]!.phrase); advance()
                case .production: _ = answerProduction(library[step.itemId]!.gap.answer); advance()
                }
            }
            if args.contains("-wpDone") { dismissSummary() }
        }
    }

    static var debugTab: MainTab? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-wpTab"), i + 1 < args.count else { return nil }
        return ["catalog": .catalog, "progress": .progress, "settings": .settings][args[i + 1]]
    }
}
#endif
