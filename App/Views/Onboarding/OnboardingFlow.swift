import SwiftUI
import UniformTypeIdentifiers

enum OnboardingStep: Hashable { case level, test, topics, prefs, voices, first }

struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model
    var done: (MainTab) -> Void = { _ in }
    @State var path: [OnboardingStep] = []
    @State var importing = false
    @State private var importError: String?

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: OnboardingStep.self) { step in
                    Group {
                        switch step {
                        case .level: LevelScreen(path: $path)
                        case .test: LevelTestScreen(path: $path)
                        case .topics: BeigeTopics(back: { path.removeLast() }, next: { path.append(.first) })
                        case .prefs: PrefsScreen(path: $path)
                        case .first: BeigeExample(back: { path.removeLast() }, done: { finish(.today) })
                        case .voices: VoicePicker(language: .english, onboarding: true)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
        }
        #if DEBUG
        .onAppear {
            let a = ProcessInfo.processInfo.arguments
            if let i = a.firstIndex(of: "-wpPickTopics"), i + 1 < a.count {
                model.updatePrefs { $0.topics = a[i + 1].components(separatedBy: "|") }
            }
            if let i = a.firstIndex(of: "-wpOnb"), i + 1 < a.count {
                path = Array([OnboardingStep.topics, .first].prefix(Int(a[i + 1]) ?? 1))
            }
        }
        #endif
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            do {
                try model.importProgress(from: url)
                model.updatePrefs { $0.onboarded = true }
            } catch {
                importError = "Не получилось прочитать файл: \(error.localizedDescription)"
            }
        }
        .alert(importError ?? "", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("Ок", role: .cancel) {}
        }
    }
}

extension OnboardingFlow {
    func finish(_ tab: MainTab) {
        done(tab)
        model.updatePrefs { $0.onboarded = true }
    }

    @ViewBuilder
    var welcome: some View {
        let a = ProcessInfo.processInfo.arguments
        let v = a.firstIndex(of: "-wpWelcome").flatMap { $0 + 1 < a.count ? WelcomeVariant(rawValue: a[$0 + 1]) : nil }
        switch v {
        case .quiz: WelcomeQuiz(start: { path.append(.level) }, restore: { importing = true })
        case .deck: WelcomeDeck(start: { path.append(.level) }, restore: { importing = true })
        case .mistake: WelcomeMistake(start: { path.append(.level) }, restore: { importing = true })
        case nil: BeigeWelcome(start: { path.append(.topics) }, restore: { importing = true })
        }
    }
}

struct WelcomeScreen: View {
    let start: () -> Void
    let restore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PatternCard(style: .waves, variant: 1, blobStart: 0.5) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("make").font(WPFont.rubik(30))
                    Text("+ a decision").font(WPFont.rubik(22, false)).foregroundStyle(Palette.inkSoft)
                }
                .padding(22)
                .frame(height: 150, alignment: .topLeading)
            }
            .rotationEffect(.degrees(-2))
            .padding(.top, 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Добро пожаловать", size: 24)
                ScreenTitle(text: "Kumi", size: 36)
                Text("English Collocations").font(WPFont.rubik(18, false)).foregroundStyle(Palette.muted)
                Text("Освойте живые английские выражения. Короткие занятия каждый день помогут говорить естественно и без пауз.")
                    .font(WPFont.nunito(18)).foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 40)

            Spacer()
            PrimaryButton(title: "Начать", action: start)
            LinkButton(title: "У меня уже есть прогресс — восстановить", action: restore)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct OnboardingHeader: View {
    let step: Int
    let back: () -> Void
    var body: some View {
        StepHeader(icon: "chevron.left", label: "Назад", action: back, counter: "\(step) из 3") {
            OnboardingSteps(current: step)
        }
    }
}

struct LevelScreen: View {
    @Environment(AppModel.self) private var model
    @Binding var path: [OnboardingStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(step: 1) { path.removeLast() }
            VStack(alignment: .leading, spacing: 6) {
                HighlightTitle(lead: "Какой у вас", mark: "уровень?")
                Text("Подберём комфортную сложность для старта. Остальные уровни тоже останутся открыты.")
                    .font(WPFont.nunito(16)).foregroundStyle(Palette.muted)
            }
            .padding(.top, 18)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(Level.allCases.enumerated()), id: \.element) { i, l in
                        let on = model.prefs.level == l
                        Button { model.updatePrefs { $0.level = l } } label: {
                            HStack(spacing: 12) {
                                Text(l.rawValue).font(WPFont.rubik(24)).frame(width: 48, alignment: .leading)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(l.name).font(WPFont.nunito(16, .heavy))
                                    Text(l.blurb).font(WPFont.nunito(14)).foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                                }
                                Spacer()
                                RadioDot(on: on)
                            }
                            .foregroundStyle(on ? Palette.ink : Palette.text)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .frame(minHeight: 72)
                            .background(on ? Palette.teal : Palette.paper, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.outline, lineWidth: on ? 0 : 1.5))
                        }
                        .buttonStyle(PressStyle())
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                    Button { path.append(.test) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle").font(.system(size: 18, weight: .semibold))
                            Text("Не уверены? Короткий тест — 12 вопросов").font(WPFont.nunito(15, .bold)).underline()
                        }
                        .foregroundStyle(Palette.text)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(.top, 22)
                .padding(.bottom, 8)
            }
            CoralButton(title: "Дальше") { path.append(.topics) }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .screenBackground()
    }
}

/// 12 recognition questions, 3 per level. Suggests the highest level with at least 2 of 3 right.
/// Answers here don't go to the schedule.
struct LevelTestScreen: View {
    @Environment(AppModel.self) private var model
    @Binding var path: [OnboardingStep]
    @State private var questions: [(Collocation, [String])] = []
    @State private var index = 0
    @State private var picked: String?
    @State private var right: [Level: Int] = [:]
    @State private var result: Level?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(icon: "xmark", label: "Закрыть тест", action: { path.removeLast() },
                       counter: questions.isEmpty ? nil : "\(min(index + 1, questions.count)) / \(questions.count)") {
                SessionProgressBar(value: questions.isEmpty ? 0 : Double(index) / Double(questions.count))
            }
            if let result {
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Готово")
                    ScreenTitle(text: "Предлагаем начать с \(result.rawValue)")
                    Text("\(result.name). Уровень можно поменять в любой момент в настройках.")
                        .font(WPFont.nunito(16)).foregroundStyle(Palette.muted)
                }
                Spacer()
                CoralButton(title: "Взять \(result.rawValue)") {
                    model.updatePrefs { $0.level = result }
                    path.removeLast()
                }
            } else if index < questions.count {
                let (item, options) = questions[index]
                Text(item.level.rawValue).font(WPFont.nunito(13, .heavy)).foregroundStyle(Palette.muted).padding(.top, 18)
                Text(model.prefs.showTranslation ? item.recognition.promptRu : "Which expression means “\(item.meaningEn)”?")
                    .font(WPFont.nunito(19, .semibold)).foregroundStyle(Palette.text).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 14) {
                    ForEach(Array(options.enumerated()), id: \.element) { i, o in
                        OptionTile(text: o, selected: picked == o) { picked = o }
                    }
                    OptionTile(text: "Не знаю", selected: picked == "") { picked = "" }
                }
                .padding(.top, 22)
                Spacer()
                CoralButton(title: "Дальше", enabled: picked != nil) {
                    if picked == item.phrase { right[item.level, default: 0] += 1 }
                    picked = nil
                    index += 1
                    if index == questions.count {
                        result = Level.allCases.last { (right[$0] ?? 0) >= 2 } ?? .a2
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .screenBackground()
        .onAppear {
            guard questions.isEmpty else { return }
            questions = Level.allCases.flatMap { l in
                model.library.items.filter { $0.level == l }.shuffled().prefix(3).map { ($0, $0.recognition.options.shuffled()) }
            }
        }
    }
}

struct TopicGrid: View {
    @Environment(AppModel.self) private var model
    @Binding var selected: Set<String>

    private func example(_ topic: String) -> String {
        model.library.items.first { $0.topics.contains(topic) && $0.level <= model.prefs.level }?.phrase
            ?? model.library.items.first { $0.topics.contains(topic) }?.phrase ?? ""
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(Array(model.library.topics.enumerated()), id: \.element) { i, t in
                let on = selected.contains(t)
                Button {
                    if on { selected.remove(t) } else { selected.insert(t) }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(on ? Color(hex: 0xF4EDDC) : .clear)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(on ? Palette.ink : .clear))
                            .overlay(Circle().stroke(on ? Palette.ink : Palette.outline, lineWidth: 2.5))
                            .opacity(on ? 1 : 0.5)
                        Text(t).font(WPFont.rubik(17, false)).multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Text(example(t)).font(WPFont.nunito(14)).foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                            .lineLimit(1)
                    }
                    .foregroundStyle(on ? Palette.ink : Palette.text)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                    .background(on ? PatternStyle.of(i).soft : Palette.paper, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.outline, lineWidth: on ? 0 : 1.5))
                }
                .buttonStyle(PressStyle())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

struct TopicsScreen: View {
    @Environment(AppModel.self) private var model
    @Binding var path: [OnboardingStep]
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(step: 2) { path.removeLast() }
            VStack(alignment: .leading, spacing: 6) {
                ScreenTitle(text: "Что вам интересно?")
                Text("Отметьте одну или несколько тем — с них начнутся рекомендации. Другие темы можно открыть в любой момент.")
                    .font(WPFont.nunito(16)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)
            ScrollView {
                TopicGrid(selected: $selected).padding(.vertical, 22).padding(.trailing, 3)
            }
            CoralButton(title: selected.isEmpty ? "Пропустить" : "Дальше · выбрано \(selected.count)") {
                model.updatePrefs { p in p.topics = model.library.topics.filter { selected.contains($0) } }
                path.append(.prefs)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .screenBackground()
        .onAppear { selected = Set(model.prefs.topics) }
    }
}

struct PrefsScreen: View {
    @Environment(AppModel.self) private var model
    @Binding var path: [OnboardingStep]

    private var accentVoices: [(Accent, VoiceInfo)] {
        let all = Speech.voices(language: "en")
        return [Accent.british, .american].compactMap { a in
            let preferred = Speech.voice(id: nil, fallbackLanguage: a.locale)?.identifier
            guard let v = all.first(where: { $0.id == preferred }) ?? all.first(where: { $0.language == a.locale }) else { return nil }
            return (a, v)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(step: 3) { path.removeLast() }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Необязательно", size: 22)
                    HighlightTitle(lead: "Перевод и", mark: "озвучка")
                    Text("Можно изменить позже в настройках.").font(WPFont.nunito(16)).foregroundStyle(Palette.muted).padding(.top, 6)

                    PaperBox(variant: 0) {
                        Toggle(isOn: Binding(get: { model.prefs.showTranslation }, set: { v in model.updatePrefs { $0.showTranslation = v } })) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Показывать перевод").font(WPFont.nunito(16, .heavy))
                                Text("Когда выражение нужно вспомнить или вписать самому, перевод скрыт до ответа")
                                    .font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                            }
                            .foregroundStyle(Palette.text)
                        }
                        .toggleStyle(WPToggleStyle())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        DashedDivider()
                        SettingsRow(title: "Язык перевода", value: "Русский", chevron: false)
                    }
                    .padding(.top, 24)

                    Text("Голос для английского").font(WPFont.rubik(19, false)).foregroundStyle(Palette.text).padding(.top, 24)
                    Text("Голоса iOS, которые уже есть на этом iPhone").font(WPFont.nunito(14)).foregroundStyle(Palette.muted).padding(.top, 2)
                    VStack(spacing: 10) {
                        ForEach(Array(accentVoices.enumerated()), id: \.element.1.id) { i, pair in
                            voiceRow(pair.0, pair.1, i)
                        }
                    }
                    .padding(.top, 10)
                    Button { path.append(.voices) } label: {
                        HStack(spacing: 4) {
                            Text("Все голоса на iPhone · \(Speech.voices(language: "en").count)").font(WPFont.nunito(15, .heavy)).underline()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.chevron)
                        }
                        .foregroundStyle(Palette.text)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.top, 18)
                .padding(.trailing, 3)
            }
            CoralButton(title: "Первое занятие · 3 карточки") { finish() }
            LinkButton(title: "Пропустить") { model.updatePrefs { $0.onboarded = true } }.frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .screenBackground()
    }

    private func voiceRow(_ accent: Accent, _ v: VoiceInfo, _ i: Int) -> some View {
        let currentId = model.prefs.englishVoiceId ?? Speech.voice(id: nil, fallbackLanguage: model.prefs.accent.locale)?.identifier
        let on = currentId == v.id
        return HStack(spacing: 8) {
            Button {
                model.updatePrefs { $0.accent = accent; $0.englishVoiceId = v.id }
            } label: {
                HStack(spacing: 12) {
                    RadioDot(on: on)
                    VStack(alignment: .leading, spacing: 0) {
                        VoiceName(voice: v, prefix: "en")
                        Text(accent == .british ? "Великобритания" : "США").font(WPFont.nunito(14)).foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                    }
                    Spacer()
                }
                .foregroundStyle(on ? Palette.ink : Palette.text)
                .padding(.leading, 14)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(on ? .isSelected : [])
            ListenButton(label: "Послушать голос \(v.name)") {
                Speech.shared.speak("Take your time, there's no rush.", voiceId: v.id, language: v.language)
            }
            .padding(.trailing, 6)
        }
        .background(on ? Palette.teal : Palette.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.outline, lineWidth: on ? 0 : 1.5))
    }

    /// First session: 3 new expressions from the first chosen topic.
    private func finish() {
        model.updatePrefs { $0.onboarded = true }
        let first = model.prefs.topics.first
        let pool = model.eligibleNewIds()
        let fromTopic = pool.filter { id in first.map { model.library[id]?.topics.contains($0) == true } ?? true }
        let ids = Array((fromTopic.count >= 3 ? fromTopic : pool).prefix(3))
        model.startSession(source: .onboarding, reviews: [], news: ids)
    }
}
