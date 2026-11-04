import Foundation

struct WordMark: Hashable {
    let word: String
    let ok: Bool
}

enum Verdict: Equatable {
    /// Matches an accepted form.
    case correct
    /// One typo in a long word, accepted on A2–B1 as Hard.
    case typoAccepted
    /// One typo on B2–C1: the expression is right, the spelling is not. Counts as a mistake.
    case spelling
    /// A real expression from the distractor list with a different meaning.
    case distractor(Distractor)
    case wrong

    var isCorrect: Bool { self == .correct || self == .typoAccepted }
}

struct CheckResult: Equatable {
    let verdict: Verdict
    /// The accepted form closest to what the user typed.
    let target: String
    /// The user's words, each marked right or wrong against `target`.
    let marks: [WordMark]
}

enum AnswerChecker {
    static func normalize(_ s: String) -> String {
        var t = s.lowercased()
        for ch in ["’", "‘", "`", "´", "ʼ"] { t = t.replacingOccurrences(of: ch, with: "'") }
        t = t.replacingOccurrences(of: "—", with: "-").replacingOccurrences(of: "–", with: "-")
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: " .,!?;:\"\n\t"))
        return t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func words(_ s: String) -> [String] { normalize(s).split(separator: " ").map(String.init) }

    static func check(_ input: String, gap: GapItem, level: Level) -> CheckResult {
        let answer = normalize(input)
        let forms = gap.acceptedForms.map(normalize)

        if let exact = forms.first(where: { $0 == answer }) {
            return CheckResult(verdict: .correct, target: exact, marks: words(answer).map { WordMark(word: $0, ok: true) })
        }

        for d in gap.distractors where normalize(d.text) == answer || normalize(d.collocation) == answer {
            let target = closest(to: answer, in: forms)
            return CheckResult(verdict: .distractor(d), target: target, marks: diff(answer, target))
        }

        for form in forms where isSingleTypo(answer, form) {
            let forgive = level.forgivesTypos && gap.typoTolerance
            return CheckResult(verdict: forgive ? .typoAccepted : .spelling, target: form, marks: diff(answer, form))
        }

        let target = closest(to: answer, in: forms)
        return CheckResult(verdict: .wrong, target: target, marks: diff(answer, target))
    }

    /// Exactly one word differs by one edit (insert, delete, substitute, swap) and that word has 5+ letters.
    static func isSingleTypo(_ answer: String, _ form: String) -> Bool {
        let a = answer.split(separator: " ").map(String.init)
        let f = form.split(separator: " ").map(String.init)
        guard a.count == f.count else { return false }
        let differing = zip(a, f).enumerated().filter { $0.element.0 != $0.element.1 }
        guard differing.count == 1, let (typed, expected) = differing.first?.element else { return false }
        return expected.count >= 5 && editDistance(typed, expected) == 1
    }

    /// Optimal string alignment distance (Damerau-Levenshtein without repeated edits).
    static func editDistance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var d = Array(repeating: Array(repeating: 0, count: y.count + 1), count: x.count + 1)
        for i in 0...x.count { d[i][0] = i }
        for j in 0...y.count { d[0][j] = j }
        for i in 1...x.count {
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, x[i - 1] == y[j - 2], x[i - 2] == y[j - 1] {
                    d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[x.count][y.count]
    }

    static func closest(to answer: String, in forms: [String]) -> String {
        let typed = Set(answer.split(separator: " ").map(String.init))
        return forms.max { lhs, rhs in
            score(typed, lhs) < score(typed, rhs)
        } ?? forms.first ?? ""
    }

    private static func score(_ typed: Set<String>, _ form: String) -> Int {
        form.split(separator: " ").filter { typed.contains(String($0)) }.count
    }

    /// Marks each typed word: same position matches when the word counts agree, otherwise membership in the target.
    static func diff(_ answer: String, _ target: String) -> [WordMark] {
        let a = answer.split(separator: " ").map(String.init)
        let t = target.split(separator: " ").map(String.init)
        if a.count == t.count {
            return zip(a, t).map { WordMark(word: $0, ok: $0 == $1) }
        }
        let set = Set(t)
        return a.map { WordMark(word: $0, ok: set.contains($0)) }
    }

    /// First letters of each word, the rest as underscores: "g____ c_______".
    static func firstLettersHint(_ answer: String) -> String {
        answer.split(separator: " ").map { word in
            guard let first = word.first else { return "" }
            return String(first) + String(repeating: "_", count: max(word.count - 1, 0))
        }.joined(separator: " ")
    }
}
