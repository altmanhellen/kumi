import XCTest
@testable import WordPartners

final class FSRSTests: XCTestCase {
    let fsrs = FSRS()

    func testInitialStabilityUsesFirstFourWeights() {
        XCTAssertEqual(fsrs.initialStability(.again), 0.212, accuracy: 1e-9)
        XCTAssertEqual(fsrs.initialStability(.good), 2.3065, accuracy: 1e-9)
    }

    func testRetrievabilityIsNinetyPercentAtStability() {
        XCTAssertEqual(fsrs.retrievability(elapsedDays: 10, stability: 10), 0.9, accuracy: 1e-9)
    }

    func testIntervalEqualsStabilityAtNinetyPercentRetention() {
        XCTAssertEqual(fsrs.interval(stability: 10), 10)
        XCTAssertEqual(fsrs.interval(stability: 0.2), 1)
        XCTAssertEqual(fsrs.interval(stability: 5000), 365)
    }

    func testGoodGrowsStabilityAndAgainShrinksIt() {
        let first = fsrs.next(state: nil, elapsedDays: 0, rating: .good)
        let good = fsrs.next(state: first, elapsedDays: 2, rating: .good)
        let again = fsrs.next(state: first, elapsedDays: 2, rating: .again)
        XCTAssertGreaterThan(good.stability, first.stability)
        XCTAssertLessThan(again.stability, first.stability)
        XCTAssertGreaterThan(again.difficulty, good.difficulty)
    }

    func testHardIsBetweenAgainAndGood() {
        let first = fsrs.next(state: nil, elapsedDays: 0, rating: .good)
        let hard = fsrs.next(state: first, elapsedDays: 3, rating: .hard)
        let good = fsrs.next(state: first, elapsedDays: 3, rating: .good)
        XCTAssertLessThan(hard.stability, good.stability)
    }

    func testFuzzIsStableForSameSeedAndStaysNear() {
        let a = fsrs.fuzzed(30, seed: 42), b = fsrs.fuzzed(30, seed: 42)
        XCTAssertEqual(a, b)
        XCTAssertTrue((27...33).contains(a))
        XCTAssertEqual(fsrs.fuzzed(2, seed: 1), 2)
    }
}

final class CardStateTests: XCTestCase {
    private func log(_ day: Int, _ rating: Rating?, kind: TaskKind = .production) -> ReviewLog {
        ReviewLog(id: UUID(), itemId: "x", time: StudyDay.date(of: day), kind: kind, correct: rating != .again,
                  usedHint: false, answerMs: 1000, rating: rating, sessionId: UUID(), deviceId: "t", scheduled: true)
    }

    func testViewingDoesNotLeaveNew() {
        var c = CardState()
        c.apply(log(100, nil, kind: .intro), fsrs: FSRS())
        c.apply(log(100, nil, kind: .recognition), fsrs: FSRS())
        XCTAssertEqual(c.state, .new)
    }

    func testFirstProductionIsLearningThenReviewingAfterAnotherDay() {
        var c = CardState()
        c.apply(log(100, .good), fsrs: FSRS())
        XCTAssertEqual(c.state, .learning)
        c.apply(log(c.dueDay!, .good), fsrs: FSRS())
        XCTAssertEqual(c.state, .reviewing)
    }

    func testAgainReturnsToLearningAndDueTomorrow() {
        var c = CardState()
        c.apply(log(100, .good), fsrs: FSRS())
        c.apply(log(103, .good), fsrs: FSRS())
        c.apply(log(110, .again), fsrs: FSRS())
        XCTAssertEqual(c.state, .learning)
        XCTAssertEqual(c.dueDay, 111)
    }

    func testMasteredAfterLongStability() {
        var c = CardState()
        var day = 100
        c.apply(log(day, .good), fsrs: FSRS())
        for _ in 0..<6 {
            day = c.dueDay!
            c.apply(log(day, .good), fsrs: FSRS())
        }
        XCTAssertGreaterThanOrEqual(c.memory!.stability, 21)
        XCTAssertEqual(c.state, .mastered)
    }
}

final class AnswerCheckerTests: XCTestCase {
    private func gap(_ answer: String, forms: [String], distractors: [Distractor] = [], typo: Bool = true) -> GapItem {
        GapItem(sentence: "I ___ today.", fullSentence: "I \(answer) today.", translationRu: "", answer: answer,
                answerWordCount: answer.split(separator: " ").count, keyWord: "", acceptedForms: forms, hintRu: "",
                typoTolerance: typo, distractors: distractors)
    }

    func testCaseSpacesAndApostrophesDoNotMatter() {
        let g = gap("don't give up", forms: ["don't give up"])
        XCTAssertEqual(AnswerChecker.check("  Don’t   GIVE up. ", gap: g, level: .b2).verdict, .correct)
    }

    func testOneTypoInLongWordAcceptedOnB1() {
        let g = gap("made a decision", forms: ["made a decision"])
        XCTAssertEqual(AnswerChecker.check("made a decsion", gap: g, level: .b1).verdict, .typoAccepted)
    }

    func testTypoIsMistakeOnC1() {
        let g = gap("grave concerns", forms: ["grave concerns"], typo: false)
        XCTAssertEqual(AnswerChecker.check("grave concerms", gap: g, level: .c1).verdict, .spelling)
    }

    func testTypoInShortWordIsWrong() {
        let g = gap("made a mistake", forms: ["made a mistake"])
        XCTAssertEqual(AnswerChecker.check("mode a mistake", gap: g, level: .a2).verdict, .wrong)
    }

    func testDistractorGetsExplanationAndWordMarks() {
        let d = Distractor(text: "growing concerns", collocation: "growing concern", meaningRu: "нарастающее", explanationRu: "…")
        let g = gap("grave concerns", forms: ["grave concerns", "grave concern"], distractors: [d], typo: false)
        let r = AnswerChecker.check("growing concerns", gap: g, level: .c1)
        XCTAssertEqual(r.verdict, .distractor(d))
        XCTAssertEqual(r.marks.map(\.ok), [false, true])
    }

    func testWrongVerbIsMarked() {
        let g = gap("make a mistake", forms: ["make a mistake", "make mistakes"])
        let r = AnswerChecker.check("do a mistake", gap: g, level: .a2)
        XCTAssertEqual(r.verdict, .wrong)
        XCTAssertEqual(r.marks.map(\.ok), [false, true, true])
    }

    func testHint() {
        XCTAssertEqual(AnswerChecker.firstLettersHint("grave concerns"), "g____ c_______")
    }
}

@MainActor
final class SessionBuildTests: XCTestCase {
    func testNewItemsComeInBatchesWithProductionAfterTwoToFourSteps() {
        let steps = AppModel.steps(reviews: ["r"], news: ["a", "b", "c", "d"])
        XCTAssertEqual(steps.first?.kind, .production)
        for id in ["a", "b", "c"] {
            let shown = steps.firstIndex { $0.itemId == id && $0.kind == .recognition }!
            let produced = steps.firstIndex { $0.itemId == id && $0.kind == .production }!
            XCTAssertTrue((3...5).contains(produced - shown), "\(id): \(produced - shown)")
        }
        XCTAssertEqual(steps.count, 1 + 4 * 3)
    }

    func testBundledContentLoads() {
        let lib = ContentLibrary.loadBundled()
        XCTAssertEqual(lib.items.count, 326)
        XCTAssertEqual(lib.topics.count, 11)
        for item in lib.items {
            XCTAssertEqual(item.recognition.options.count, 3)
            XCTAssertTrue(item.recognition.options.contains(item.phrase))
            XCTAssertTrue(item.gap.sentence.contains("___"))
            let r = AnswerChecker.check(item.gap.answer, gap: item.gap, level: item.level)
            XCTAssertEqual(r.verdict, .correct, item.id)
        }
    }
}
