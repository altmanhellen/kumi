import SwiftUI

/// Full-screen session: close, progress, task, main action at the bottom. No tab bar.
struct SessionView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if let summary = model.lastSummary, model.session == nil {
                SummaryView(summary: summary)
            } else if let s = model.session, let step = s.current, let item = model.library[step.itemId] {
                VStack(spacing: 0) {
                    StepHeader(icon: "xmark", label: "Закрыть занятие", action: { model.closeSession() },
                               counter: "\(min(s.index + 1, s.steps.count)) / \(s.steps.count)") {
                        SessionProgressBar(value: s.progress)
                            .accessibilityElement()
                            .accessibilityLabel("Прогресс занятия")
                            .accessibilityValue("шаг \(s.index + 1) из \(s.steps.count)")
                    }
                    .padding(.horizontal, 20)
                    Group {
                        switch step.kind {
                        case .intro: IntroStep(item: item)
                        case .recognition: RecognizeStep(item: item, step: step)
                        case .production: ProduceStep(item: item, step: step, initialDraft: s.draft)
                        }
                    }
                    .id(step.id)
                    .transition(.opacity)
                }
                .animation(.easeOut(duration: 0.2), value: s.index)
            } else {
                Color.clear.onAppear { model.showingSession = false }
            }
        }
        .screenBackground()
        .onDisappear { Speech.shared.stop() }
    }
}

struct IntroStep: View {
    @Environment(AppModel.self) private var model
    let item: Collocation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Tag(text: "Новое · \(item.structureSet)", icon: "sparkles", fill: Palette.lilac)
                        Spacer()
                        Button { model.toggleFavorite(item.id) } label: {
                            Image(systemName: model.isFavorite(item.id) ? "star.fill" : "star")
                                .font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.text).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(model.isFavorite(item.id) ? "Убрать из избранного" : "Добавить в избранное")
                        .padding(.trailing, -8)
                    }
                    .padding(.top, 18)

                    PatternCard(style: .waves, variant: 1, blobStart: 0.78) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(item.level.rawValue) · \(item.topics.first ?? item.structureSet)")
                                .font(WPFont.nunito(14, .heavy))
                                .foregroundStyle(Palette.inkSoft)
                            Text(item.phrase)
                                .font(WPFont.rubik(36))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 10)
                            Text(item.meaningEn)
                                .font(WPFont.nunito(18, .bold))
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 10)
                            if model.prefs.showTranslation {
                                Text(item.translationRu)
                                    .font(WPFont.nunito(16))
                                    .foregroundStyle(Palette.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                            }
                            Spacer(minLength: 16)
                            HStack(spacing: 10) {
                                Button { model.speakEnglish(item.phrase) } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color(hex: 0xF4EDDC))
                                        .frame(width: 48, height: 48)
                                        .background(Circle().fill(Palette.ink))
                                }
                                .buttonStyle(PressStyle())
                                .accessibilityLabel("Слушать: \(item.phrase)")
                                SlowPill(rate: model.prefs.slowRate, height: 48) { model.speakEnglish(item.phrase, slow: true) }
                            }
                        }
                        .padding(.leading, 22)
                        .padding(.trailing, 76)
                        .padding(.vertical, 20)
                        .frame(minHeight: 300, alignment: .topLeading)
                    }
                    .padding(.top, 10)

                    if let ex = item.example {
                        ExampleBox(en: ex.en, ru: model.prefs.showTranslation ? ex.ru : nil, highlight: item.phrase) {
                            model.speakEnglish(ex.en)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 12)
            }
            PrimaryButton(title: "Понятно, дальше") { model.answerIntro(alreadyKnown: false) }
            LinkButton(title: "Уже знаю — сразу проверить") { model.answerIntro(alreadyKnown: true) }
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}

/// Colored option card with a selection circle on the right.
struct OptionTile: View {
    let text: String
    let style: PatternStyle
    var selected = false
    /// Another card is selected, so this one steps back.
    var dimmed = false
    var state: OptionState = .idle
    /// Translation shown under the phrase once the answer is checked.
    var note: String?
    let action: () -> Void

    enum OptionState { case idle, right, wrong }

    private var lifted: Bool { selected || state == .right }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(text)
                        .font(WPFont.rubik(20, false))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Palette.cream.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
                    if let note {
                        Text(note)
                            .font(WPFont.nunito(13, .bold))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Palette.cream, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.leading, 18)
                .padding(.vertical, note == nil ? 12 : 8)
                Spacer(minLength: 8)
                circle.padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .background {
                ZStack {
                    style.fill
                    PatternFill(style: style).opacity(0.55).mask(
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    )
                }
                .opacity(state == .wrong ? 0.4 : 1)
                .background(Palette.background)
                .clipShape(Radii.shape(style.rawValue))
            }
            .overlay(Radii.shape(style.rawValue).stroke(Palette.outline, lineWidth: 2.5))
            .background(Radii.shape(style.rawValue).fill(Palette.outline).offset(x: lifted ? 5 : 0, y: lifted ? 5 : 0))
            .offset(x: lifted ? -3 : 0, y: lifted ? -3 : 0)
            .opacity(dimmed ? 0.5 : 1)
            .animation(.easeOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(lifted ? .isSelected : [])
        .accessibilityValue(state == .right ? "верно" : state == .wrong ? "неверно" : "")
    }

    private var circle: some View {
        let filled = lifted
        return Circle()
            .fill(filled ? Palette.ink : Color(hex: 0xFFFBF1))
            .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
            .overlay {
                if filled {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .black)).foregroundStyle(Color(hex: 0xFFFBF1))
                }
            }
            .frame(width: 32, height: 32)
            .opacity(state == .wrong ? 0.5 : 1)
            .accessibilityHidden(true)
    }
}

/// Bottom sheet with a wavy top edge.
struct WavyTop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let amp: CGFloat = 7, wave: CGFloat = 46
        p.move(to: CGPoint(x: r.minX, y: r.minY + amp))
        var x = r.minX
        while x < r.maxX {
            p.addQuadCurve(to: CGPoint(x: min(x + wave, r.maxX), y: r.minY + amp),
                           control: CGPoint(x: x + wave / 2, y: r.minY - amp))
            x += wave
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct RecognizeStep: View {
    @Environment(AppModel.self) private var model
    let item: Collocation
    let step: SessionStep
    @State private var options: [String] = []
    @State private var picked: String?
    @State private var checked = false
    @State private var correct = false

    private var question: String {
        model.prefs.showTranslation ? item.recognition.promptRu : "Which expression means “\(item.meaningEn)”?"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView { task }
                .padding(.horizontal, 20)
            if checked {
                sheet
            } else {
                PrimaryButton(title: "Проверить", enabled: picked != nil) {
                    guard let p = picked else { return }
                    correct = model.answerRecognition(p)
                    checked = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            if options.isEmpty { options = model.recognitionOptions(for: item) }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-wpPickWrong") {
                picked = options.first { $0 != item.phrase }
                correct = model.answerRecognition(picked!)
                checked = true
            } else if ProcessInfo.processInfo.arguments.contains("-wpPickRight") {
                picked = item.phrase
                if ProcessInfo.processInfo.arguments.contains("-wpCheck") {
                    correct = model.answerRecognition(item.phrase)
                    checked = true
                }
            }
            #endif
        }
    }

    private var task: some View {
        VStack(alignment: .leading, spacing: 0) {
            if step.retry {
                Tag(text: "Ещё раз · с опорой", icon: "arrow.uturn.backward", fill: Palette.peach).padding(.top, 18)
            }
            ScreenTitle(text: "Выберите выражение", size: 29).padding(.top, 18)
            Text(question)
                .font(WPFont.nunito(19, .semibold))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            VStack(spacing: 14) {
                ForEach(Array(options.enumerated()), id: \.element) { i, o in
                    OptionTile(
                        text: o, style: .of(i),
                        selected: !checked && picked == o,
                        dimmed: !checked && picked != nil && picked != o,
                        state: checked ? (o == item.phrase ? .right : .wrong) : .idle,
                        note: checked ? model.optionMeaning(o, for: item) : nil
                    ) {
                        if !checked { picked = o }
                    }
                }
            }
            .padding(.top, checked ? 18 : 24)
        }
        .padding(.bottom, 16)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(correct ? "Верно!" : "Не совсем").font(WPFont.rubik(28)).accessibilityAddTraits(.isHeader)
            if !correct, let why = model.optionExplanation(picked ?? "", for: item) {
                Text(why).font(WPFont.nunito(15)).fixedSize(horizontal: false, vertical: true)
            }
            (Text(item.phrase).font(WPFont.nunito(16, .heavy)) + Text(" — \(model.prefs.showTranslation ? item.translationRu : item.meaningEn)").font(WPFont.nunito(16)))
                .fixedSize(horizontal: false, vertical: true)
            let sentence = item.example?.en ?? item.gap.fullSentence
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ExampleBox.bolded(sentence, item.phrase)).font(WPFont.nunito(16, .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    if model.prefs.showTranslation {
                        Text(item.example?.ru ?? item.gap.translationRu).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                ListenButton(label: "Послушать пример") { model.speakEnglish(sentence) }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Palette.cream, in: Radii.shape(1))
            .overlay(Radii.shape(1).stroke(Palette.ink, lineWidth: 2.5))
            PrimaryButtonInk(title: "Дальше") { model.advance() }
                .padding(.top, 6)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            WavyTop()
                .fill(correct ? Palette.teal : Palette.peach)
                .overlay(WavyTop().stroke(Palette.outline, lineWidth: 2.5))
                .ignoresSafeArea(edges: .bottom)
        }
        .transition(.move(edge: .bottom))
    }
}

/// Main button that stays dark on light colored panels in both themes.
struct PrimaryButtonInk: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WPFont.rubik(19, false, relativeTo: .headline))
                .foregroundStyle(Color(hex: 0xF4EDDC))
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Palette.ink)
                .clipShape(TornShape())
        }
        .buttonStyle(PressStyle())
    }
}

/// Result card: verdict, explanation, example with translation and a listen button.
struct FeedbackCard<Extra: View>: View {
    let title: String
    let good: Bool
    var text: String?
    var phrase: String?
    var meaning: String?
    let sentence: String
    let translation: String?
    var highlight: String?
    let listen: () -> Void
    @ViewBuilder var extra: Extra

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(WPFont.rubik(28)).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
            extra
            if let text {
                Text(text).font(WPFont.nunito(16)).fixedSize(horizontal: false, vertical: true)
            }
            if let phrase, let meaning {
                (Text(phrase).font(WPFont.nunito(16, .heavy)) + Text(" — \(meaning)").font(WPFont.nunito(16)))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ExampleBox.bolded(sentence, highlight)).font(WPFont.nunito(16, .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    if let translation {
                        Text(translation).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                ListenButton(label: "Послушать пример", action: listen)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Palette.cream, in: Radii.shape(1))
            .overlay(Radii.shape(1).stroke(Palette.ink, lineWidth: 2.5))
        }
        .foregroundStyle(Palette.ink)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                (good ? PatternStyle.waves : PatternStyle.hatch).base
                PatternFill(style: good ? .waves : .hatch).opacity(0.35)
                    .clipShape(SideBlob(start: 0.82, variant: 1))
            }
            .clipShape(WobblyRect(variant: 3))
        }
        .overlay(WobblyRect(variant: 3).stroke(Palette.outline, lineWidth: 2.5))
        .accessibilityElement(children: .contain)
    }
}

extension FeedbackCard where Extra == EmptyView {
    init(title: String, good: Bool, text: String?, phrase: String?, meaning: String?, sentence: String,
         translation: String?, highlight: String?, listen: @escaping () -> Void) {
        self.init(title: title, good: good, text: text, phrase: phrase, meaning: meaning, sentence: sentence,
                  translation: translation, highlight: highlight, listen: listen) { EmptyView() }
    }
}
