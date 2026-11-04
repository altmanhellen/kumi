import AVFoundation
import Foundation
import Observation

struct VoiceInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality

    var regionTitle: String {
        let region = language.split(separator: "-").last.map(String.init) ?? ""
        let names: [String: String] = [
            "GB": "Великобритания", "US": "США", "AU": "Австралия", "IE": "Ирландия", "IN": "Индия",
            "ZA": "ЮАР", "CA": "Канада", "NZ": "Новая Зеландия", "SC": "Шотландия", "RU": "Россия",
        ]
        let base = names[region] ?? Locale(identifier: "ru").localizedString(forRegionCode: region) ?? region
        switch quality {
        case .premium: return base + " · премиум"
        case .enhanced: return base + " · улучшенный"
        default: return base
        }
    }

    var short: String {
        let region = language.split(separator: "-").last.map(String.init) ?? ""
        return region == "GB" ? "\(name) · UK" : region.isEmpty ? name : "\(name) · \(region)"
    }
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

    static func voices(language prefix: String) -> [VoiceInfo] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(prefix) && !$0.voiceTraits.contains(.isNoveltyVoice) }
            .map { VoiceInfo(id: $0.identifier, name: $0.name, language: $0.language, quality: $0.quality) }
            .sorted { ($0.language, -$0.quality.rawValue, $0.name) < ($1.language, -$1.quality.rawValue, $1.name) }
    }

    /// The system's default voice for a language ("en" or "ru"), marked «(системный)» in voice lists.
    static func systemVoiceId(language prefix: String) -> String? {
        let current = AVSpeechSynthesisVoice.currentLanguageCode()
        let code = current.hasPrefix(prefix) ? current : (prefix == "en" ? "en-US" : "ru-RU")
        return AVSpeechSynthesisVoice(language: code)?.identifier
    }

    /// The chosen voice if it is still installed, otherwise the system default for the accent or language.
    static func voice(id: String?, fallbackLanguage: String) -> AVSpeechSynthesisVoice? {
        if let id, let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        if fallbackLanguage == "en-GB",
           let daniel = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == "en-GB" && $0.name == "Daniel" }) {
            return daniel
        }
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

    var englishVoiceName: String {
        Speech.voice(id: prefs.englishVoiceId, fallbackLanguage: prefs.accent.locale).map {
            VoiceInfo(id: $0.identifier, name: $0.name, language: $0.language, quality: $0.quality).short
        } ?? "по умолчанию"
    }

    var russianVoiceName: String {
        Speech.voice(id: prefs.russianVoiceId, fallbackLanguage: "ru-RU")?.name ?? "по умолчанию"
    }
}
