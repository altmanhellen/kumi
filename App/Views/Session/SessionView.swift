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

/// Plain answer row: dashed circle and phrase; after checking it turns green or red with a pattern band.
struct OptionTile: View {
    let text: String
    var style: PatternStyle = .waves
    var selected = false
    var dimmed = false
    var state: OptionState = .idle
    /// Translation shown under the phrase once the answer is checked.
    var note: String?
    let action: () -> Void

    enum OptionState { case idle, right, wrong }

    private var fill: Color {
        switch state {
        case .right: Color(hex: 0xD3EBD9)
        case .wrong: Color(hex: 0xF8D5CC)
        case .idle: selected ? Color(hex: 0xFFF1BF) : Color(hex: 0xFFFBF1)
        }
    }

    private var raised: Bool { selected || state != .idle }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                circle
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(WPFont.rubik(19, false))
                        .multilineTextAlignment(.leading)
                    if let note {
                        Text(note).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.ink)
            .padding(.leading, 14)
            .padding(.trailing, state == .idle ? 14 : 92)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background {
                ZStack(alignment: .trailing) {
                    fill
                    if state != .idle {
                        PatternFill(style: state == .right ? .waves : .hatch)
                            .colorMultiply(.white)
                            .overlay(band)
                            .frame(width: 84)
                            .clipShape(SideBlob(start: 0.12, variant: 1))
                    }
                }
                .clipShape(Radii.shape(1))
            }
            .overlay(Radii.shape(1).stroke(Palette.ink, lineWidth: raised ? 3 : 2.5))
            .background(Radii.shape(1).fill(Palette.ink).offset(x: raised ? 3 : 0, y: raised ? 3 : 0))
            .opacity(dimmed ? 0.5 : 1)
            .animation(.easeOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected || state == .right ? .isSelected : [])
        .accessibilityValue(state == .right ? "верно" : state == .wrong ? "неверно" : "")
    }

    /// Green waves or red cross-hatch on the right edge.
    private var band: some View {
        Canvas { ctx, size in
            let good = state == .right
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(good ? Color(hex: 0xA6D5B4) : Color(hex: 0xF0A08C)))
            let ink = good ? Color(hex: 0x2F7D4F) : Color(hex: 0xC8452F)
            if good {
                var y: CGFloat = 12
                while y < size.height + 8 {
                    var p = Path(); var x: CGFloat = -6
                    p.move(to: CGPoint(x: x, y: y))
                    while x < size.width + 12 { p.addQuadCurve(to: CGPoint(x: x + 14, y: y), control: CGPoint(x: x + 7, y: y - 7)); x += 14 }
                    ctx.stroke(p, with: .color(ink), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    y += 18
                }
            } else {
                var p = Path(); var x: CGFloat = -size.height
                while x < size.width + size.height {
                    p.move(to: CGPoint(x: x, y: size.height)); p.addLine(to: CGPoint(x: x + size.height * 0.5, y: 0))
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x + size.height * 0.5, y: size.height))
                    x += 22
                }
                ctx.stroke(p, with: .color(ink), lineWidth: 2.5)
            }
        }
    }

    @ViewBuilder
    private var circle: some View {
        switch state {
        case .right:
            Image(systemName: "checkmark").font(.system(size: 12, weight: .black)).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(Circle().fill(Color(hex: 0x2F7D4F)))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2))
        case .wrong:
            Image(systemName: "xmark").font(.system(size: 12, weight: .black)).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(Circle().fill(Color(hex: 0xC8452F)))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2))
        case .idle:
            if selected {
                Circle().fill(Color(hex: 0xFFF1BF))
                    .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
                    .overlay(Circle().fill(Palette.ink).frame(width: 12, height: 12))
                    .frame(width: 26, height: 26)
            } else {
                Circle().stroke(Color(hex: 0x8A8073), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .frame(width: 26, height: 26)
            }
        }
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

    /// Question as a heading, with the quoted meaning under a yellow highlighter.
    private var question: AttributedString {
        let raw = model.prefs.showTranslation ? item.recognition.promptRu : "Which expression means “\(item.meaningEn)”?"
        var a = AttributedString(raw)
        let pairs: [(String, String)] = [("«", "»"), ("“", "”")]
        for (open, close) in pairs {
            if let o = a.range(of: open), let c = a[o.upperBound...].range(of: close) {
                a[o.upperBound..<c.lowerBound].backgroundColor = Color(hex: 0xF9E08A)
                a[o.upperBound..<c.lowerBound].foregroundColor = Palette.ink
            }
        }
        return a
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if step.retry {
                        Tag(text: "Ещё раз · с опорой", icon: "arrow.uturn.backward", fill: Palette.peach).padding(.top, 18)
                    }
                    Text(WPFont.handText("Выберите выражение")).font(WPFont.hand(22)).foregroundStyle(Color(hex: 0x645C52)).padding(.top, 16)
                    Text(question)
                        .font(WPFont.rubik(24))
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 10) {
                        ForEach(options, id: \.self) { o in
                            OptionTile(
                                text: o,
                                selected: !checked && picked == o,
                                state: rowState(o),
                                note: checked ? model.optionMeaning(o, for: item) : nil
                            ) {
                                if !checked { picked = o }
                            }
                        }
                    }
                    .padding(.top, 20)
                    if checked { plate.padding(.top, 14) }
                }
                .padding(.trailing, 3)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            if checked {
                PrimaryButton(title: "Дальше") { model.advance() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
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

    private func rowState(_ o: String) -> OptionTile.OptionState {
        guard checked else { return .idle }
        if o == item.phrase { return .right }
        if o == picked { return .wrong }
        return .idle
    }

    private var plate: some View {
        let sentence = item.example?.en ?? item.gap.fullSentence
        return VStack(alignment: .leading, spacing: 8) {
            Text(correct ? "Верно!" : "Не совсем")
                .font(WPFont.rubik(22))
                .foregroundStyle(correct ? Color(hex: 0x2F7D4F) : Color(hex: 0xB23A24))
                .accessibilityAddTraits(.isHeader)
            Group {
                if !correct, let why = model.optionExplanation(picked ?? "", for: item) {
                    Text(why)
                } else {
                    Text(item.phrase).font(WPFont.nunito(15, .heavy)) + Text(" — \(model.prefs.showTranslation ? item.translationRu : item.meaningEn)")
                }
            }
            .font(WPFont.nunito(15))
            .fixedSize(horizontal: false, vertical: true)
            DashedDivider.Line()
                .stroke(correct ? Color(hex: 0xBFDCC6) : Color(hex: 0xF1C4B8), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                .frame(height: 2)
                .padding(.vertical, 2)
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ExampleBox.bolded(sentence, item.phrase)).font(WPFont.nunito(15))
                        .fixedSize(horizontal: false, vertical: true)
                    if model.prefs.showTranslation {
                        Text(item.example?.ru ?? item.gap.translationRu).font(WPFont.nunito(13)).foregroundStyle(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                ListenButton(label: "Послушать пример") { model.speakEnglish(sentence) }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? Color(hex: 0xE8F3EA) : Color(hex: 0xFBE9E4), in: Radii.shape(2))
        .overlay(Radii.shape(2).stroke(correct ? Color(hex: 0xBFDCC6) : Color(hex: 0xF1C4B8), lineWidth: 2))
        .accessibilityElement(children: .contain)
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
