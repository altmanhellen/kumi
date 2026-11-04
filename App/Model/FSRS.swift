import Foundation

/// Answer grade the app derives from the task result. The user never picks it.
enum Rating: Int, Codable, Comparable {
    case again = 1, hard = 2, good = 3, easy = 4
    static func < (l: Rating, r: Rating) -> Bool { l.rawValue < r.rawValue }
}

struct MemoryState: Codable, Equatable {
    var stability: Double
    var difficulty: Double
}

/// FSRS-6 scheduler with whole-day intervals.
struct FSRS {
    static let defaultWeights: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796,
        1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ]

    var w: [Double] = FSRS.defaultWeights
    var desiredRetention: Double = 0.9
    var maximumInterval = 365

    private var decay: Double { -w[20] }
    private var factor: Double { pow(0.9, 1 / decay) - 1 }

    func retrievability(elapsedDays t: Double, stability s: Double) -> Double {
        pow(1 + factor * t / s, decay)
    }

    func initialStability(_ r: Rating) -> Double { max(w[r.rawValue - 1], 0.001) }

    func initialDifficulty(_ r: Rating, clamp: Bool = true) -> Double {
        let d = w[4] - exp(w[5] * Double(r.rawValue - 1)) + 1
        return clamp ? min(max(d, 1), 10) : d
    }

    func nextDifficulty(_ d: Double, _ r: Rating) -> Double {
        let delta = -w[6] * Double(r.rawValue - 3)
        let damped = d + delta * (10 - d) / 9
        let reverted = w[7] * initialDifficulty(.easy, clamp: false) + (1 - w[7]) * damped
        return min(max(reverted, 1), 10)
    }

    func recallStability(d: Double, s: Double, r: Double, rating: Rating) -> Double {
        let hardPenalty = rating == .hard ? w[15] : 1
        let easyBonus = rating == .easy ? w[16] : 1
        return s * (1 + exp(w[8]) * (11 - d) * pow(s, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hardPenalty * easyBonus)
    }

    func forgetStability(d: Double, s: Double, r: Double) -> Double {
        let longTerm = w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp(w[14] * (1 - r))
        let cap = s / exp(w[17] * w[18])
        return min(longTerm, cap)
    }

    func shortTermStability(s: Double, rating: Rating) -> Double {
        let inc = exp(w[17] * (Double(rating.rawValue) - 3 + w[18])) * pow(s, -w[19])
        let next = s * inc
        return rating >= .good ? max(next, s) : next
    }

    /// New memory state after a rated answer given `elapsedDays` since the previous rated answer.
    func next(state: MemoryState?, elapsedDays: Int, rating: Rating) -> MemoryState {
        guard let state else {
            return MemoryState(stability: initialStability(rating), difficulty: initialDifficulty(rating))
        }
        let s: Double
        if elapsedDays == 0 {
            s = shortTermStability(s: state.stability, rating: rating)
        } else {
            let r = retrievability(elapsedDays: Double(elapsedDays), stability: state.stability)
            s = rating == .again
                ? forgetStability(d: state.difficulty, s: state.stability, r: r)
                : recallStability(d: state.difficulty, s: state.stability, r: r, rating: rating)
        }
        return MemoryState(stability: min(max(s, 0.001), 36500), difficulty: nextDifficulty(state.difficulty, rating))
    }

    /// Interval in days before fuzz.
    func interval(stability s: Double) -> Int {
        let raw = s / factor * (pow(desiredRetention, 1 / decay) - 1)
        return min(max(Int(raw.rounded()), 1), maximumInterval)
    }

    /// Spreads cards learned on one day so they don't always come back together.
    /// `seed` keeps the result stable when the log is replayed.
    func fuzzed(_ interval: Int, seed: UInt64) -> Int {
        let ivl = Double(interval)
        guard ivl >= 2.5 else { return interval }
        let ranges: [(Double, Double, Double)] = [(2.5, 7, 0.15), (7, 20, 0.1), (20, .infinity, 0.05)]
        var delta = 1.0
        for (start, end, f) in ranges { delta += f * max(min(ivl, end) - start, 0) }
        let lo = max(2, Int((ivl - delta).rounded()))
        let hi = min(Int((ivl + delta).rounded()), maximumInterval)
        guard hi > lo else { return min(max(interval, 1), maximumInterval) }
        var rng = SplitMix64(seed: seed)
        return lo + Int(rng.next() % UInt64(hi - lo + 1))
    }
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension UUID {
    var seed: UInt64 {
        withUnsafeBytes(of: uuid) { $0.load(as: UInt64.self) }
    }
}
