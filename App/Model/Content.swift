import Foundation

enum Level: String, Codable, CaseIterable, Identifiable, Comparable {
    case a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1"

    var id: String { rawValue }
    var order: Int { Level.allCases.firstIndex(of: self)! }
    var name: String {
        switch self {
        case .a2: "Elementary"
        case .b1: "Intermediate"
        case .b2: "Upper-intermediate"
        case .c1: "Advanced"
        }
    }
    var blurb: String {
        switch self {
        case .a2: "Быт, покупки, простые разговоры"
        case .b1: "Работа, поездки, обычное общение"
        case .b2: "Свободно обсуждаю разные темы"
        case .c1: "Нюансы, деловой и академический стиль"
        }
    }
    var next: Level? { order + 1 < Level.allCases.count ? Level.allCases[order + 1] : nil }
    /// A2–B1 forgive one typo, B2–C1 need exact spelling.
    var forgivesTypos: Bool { self == .a2 || self == .b1 }

    static func < (l: Level, r: Level) -> Bool { l.order < r.order }
}

struct Example: Codable, Hashable {
    let en: String
    let ru: String
    let grammar: String?
}

struct Distractor: Codable, Hashable {
    let text: String
    let collocation: String
    let meaningRu: String
    let explanationRu: String

    enum CodingKeys: String, CodingKey {
        case text, collocation
        case meaningRu = "meaning_ru"
        case explanationRu = "explanation_ru"
    }
}

struct GapItem: Codable, Hashable {
    let sentence: String
    let fullSentence: String
    let translationRu: String
    let answer: String
    let answerWordCount: Int
    let keyWord: String
    let acceptedForms: [String]
    let hintRu: String
    let typoTolerance: Bool
    let distractors: [Distractor]

    enum CodingKeys: String, CodingKey {
        case sentence, answer, distractors
        case fullSentence = "full_sentence"
        case translationRu = "translation_ru"
        case answerWordCount = "answer_word_count"
        case keyWord = "key_word"
        case acceptedForms = "accepted_forms"
        case hintRu = "hint_ru"
        case typoTolerance = "typo_tolerance"
    }

    /// Sentence split around the gap.
    var parts: (before: String, after: String) {
        let pieces = sentence.components(separatedBy: "___")
        return (pieces.first ?? "", pieces.count > 1 ? pieces[1] : "")
    }
}

struct Recognition: Codable, Hashable {
    let promptRu: String
    let options: [String]

    enum CodingKeys: String, CodingKey {
        case promptRu = "prompt_ru"
        case options
    }
}

struct Collocation: Codable, Identifiable, Hashable {
    let id: String
    let level: Level
    let structureSet: String
    let phrase: String
    let meaningEn: String
    let translationRu: String
    let topics: [String]
    let examples: [Example]
    let gap: GapItem
    let recognition: Recognition

    enum CodingKeys: String, CodingKey {
        case id, level, phrase, topics, examples, gap, recognition
        case structureSet = "structure_set"
        case meaningEn = "meaning_en"
        case translationRu = "translation_ru"
    }

    var example: Example? { examples.first }

    func distractor(for collocation: String) -> Distractor? {
        gap.distractors.first { $0.collocation == collocation }
    }
}

struct ContentFile: Codable {
    let version: String
    let topics: [String]
    let items: [Collocation]
}

final class ContentLibrary {
    let version: String
    let topics: [String]
    let items: [Collocation]
    let byId: [String: Collocation]
    /// Structure groups in the order they first appear in the content (Make, Do, Take…).
    let structureSets: [String]

    init(file: ContentFile) {
        version = file.version
        topics = file.topics
        items = file.items
        byId = Dictionary(uniqueKeysWithValues: file.items.map { ($0.id, $0) })
        var seen: [String] = []
        for item in file.items where !seen.contains(item.structureSet) { seen.append(item.structureSet) }
        structureSets = seen
    }

    static func loadBundled() -> ContentLibrary {
        guard let url = Bundle.main.url(forResource: "word-partners-content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ContentFile.self, from: data) else {
            fatalError("Bundled content is missing or broken")
        }
        return ContentLibrary(file: file)
    }

    subscript(id: String) -> Collocation? { byId[id] }
}
