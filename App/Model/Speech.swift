import AVFoundation
import Foundation
import Observation

struct VoiceInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality
    var isPersonal = false

    init(_ v: AVSpeechSynthesisVoice) {
        id = v.identifier
        name = v.name
        language = v.language
        quality = v.quality
        isPersonal = v.voiceTraits.contains(.isPersonalVoice)
    }

    /// Voices from before iOS 16 (Eloquence and the old macOS set) sound robotic; they go to a folded list.
    var isLegacy: Bool {
        id.hasPrefix("com.apple.eloquence") || id.hasPrefix("com.apple.speech.synthesis")
    }

    /// Premium, enhanced and Personal Voice: the natural-sounding ones.
    var isModern: Bool { isPersonal || quality == .premium || quality == .enhanced }

    var regionName: String {
        if let a = Accent(locale: language) { return a.title }
        let region = language.split(separator: "-").last.map(String.init) ?? ""
        let names: [String: String] = ["CA": "Канада", "NZ": "Новая Зеландия", "SC": "Шотландия", "RU": "Россия"]
        return names[region] ?? Locale(identifier: "ru").localizedString(forRegionCode: region) ?? region
    }

    var qualityName: String? {
        if isPersonal { return "личный голос" }
        switch quality {
        case .premium: return "премиум"
        case .enhanced: return "улучшенный"
        default: return nil
        }
    }

    var regionTitle: String {
        qualityName.map { regionName + " · " + $0 } ?? regionName
    }

    var short: String {
        let region = language.split(separator: "-").last.map(String.init) ?? ""
        return region == "GB" ? "\(name) · UK" : region.isEmpty ? name : "\(name) · \(region)"
    }
}

/// The list of iOS voices. Asking iOS for voices the first time takes seconds on a real iPhone,
/// so the list is read once in the background at launch and screens only read this copy.
@MainActor
@Observable
final class VoiceCatalog {
    static let shared = VoiceCatalog()

    private(set) var all: [VoiceInfo] = []
    private(set) var loaded = false
    /// System default voice id for each language code, e.g. "en-GB" → Daniel.
    private(set) var systemIds: [String: String] = [:]
    private var loading = false

    func load(force: Bool = false) {
        guard !loading, force || !loaded else { return }
        loading = true
        // A plain background queue, not a Swift task: the speech framework blocks inside this call
        // and warns when that happens on a Swift concurrency thread.
        DispatchQueue.global(qos: .utility).async {
            let voices = AVSpeechSynthesisVoice.speechVoices()
                .filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
                .map(VoiceInfo.init)
            var ids: [String: String] = [:]
            for code in Accent.allCases.map(\.locale) + ["ru-RU"] {
                ids[code] = AVSpeechSynthesisVoice(language: code)?.identifier
            }
            let sorted = voices.sorted {
                ($0.language, -$0.quality.rawValue, $0.name) < ($1.language, -$1.quality.rawValue, $1.name)
            }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.all = sorted
                    self.systemIds = ids
                    self.loaded = true
                    self.loading = false
                }
            }
        }
    }

    func voices(language prefix: String) -> [VoiceInfo] { all.filter { $0.language.hasPrefix(prefix) } }

    func info(id: String?) -> VoiceInfo? { id.flatMap { id in all.first { $0.id == id } } }

    /// The voice chosen for this language in the iPhone settings (Accessibility → Spoken Content → Voices).
    func system(locale: String) -> VoiceInfo? { info(id: systemIds[locale]) }
}

/// Speaks with the voices built into iOS. Only one phrase plays at a time.
@MainActor
@Observable
final class Speech: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speech()

    private let synth = AVSpeechSynthesizer()
    private(set) var speakingText: String?

    override init() {
        super.init()
        synth.delegate = self
    }

    /// The chosen voice if it is still installed, otherwise the iPhone's own voice for the accent or language.
    static func voice(id: String?, fallbackLanguage: String) -> AVSpeechSynthesisVoice? {
        if let id, let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        return AVSpeechSynthesisVoice(language: fallbackLanguage)
    }

    func speak(_ text: String, voiceId: String?, language: String, slow: Bool = false, slowRate: Double = 0.7) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let u = AVSpeechUtterance(string: text)
        u.voice = Self.voice(id: voiceId, fallbackLanguage: language)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * Float(slow ? slowRate : 1.0)
        speakingText = text
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        speakingText = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.speakingText = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingText = nil }
    }
}

extension AppModel {
    func speakEnglish(_ text: String, slow: Bool = false) {
        Speech.shared.speak(text, voiceId: prefs.englishVoiceId, language: prefs.accent.locale, slow: slow, slowRate: prefs.slowRate)
    }

    func speakRussian(_ text: String) {
        Speech.shared.speak(text, voiceId: prefs.russianVoiceId, language: "ru-RU")
    }

    /// Name for the settings row. Reads the cached list, so opening Settings never waits for iOS.
    var englishVoiceName: String {
        let catalog = VoiceCatalog.shared
        if let v = catalog.info(id: prefs.englishVoiceId) { return v.short }
        guard catalog.loaded else { return "" }
        if let v = catalog.system(locale: prefs.accent.locale) { return v.name }
        return "как в iPhone"
    }
}
