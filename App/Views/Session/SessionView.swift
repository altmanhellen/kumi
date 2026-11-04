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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.phrase)
                                .font(WPFont.rubik(36))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(item.phrase)
                            Text("\(item.level.rawValue) · \(item.topics.first ?? "")").font(WPFont.nunito(15)).foregroundStyle(Palette.inkSoft)
                            HStack(spacing: 10) {
                                ListenPill(title: "Слушать") { model.speakEnglish(item.phrase) }
                                SlowPill(rate: model.prefs.slowRate) { model.speakEnglish(item.phrase, slow: true) }
                            }
                            .padding(.top, 14)
                        }
                        .padding(.horizontal, 22).padding(.vertical, 20)
                        .frame(width: 280, alignment: .leading)
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Значение").font(WPFont.hand(21)).foregroundStyle(Palette.muted)
                        Text(item.meaningEn).font(WPFont.nunito(18, .bold)).foregroundStyle(Palette.text)
                        if model.prefs.showTranslation {
                            Text(item.translationRu).font(WPFont.nunito(16)).foregroundStyle(Palette.secondary)
                        }
                    }
                    .padding(.top, 22)

                    if let ex = item.example {
                        ExampleBox(en: ex.en, ru: model.prefs.showTranslation ? ex.ru : nil, highlight: item.phrase) {
                            model.speakEnglish(ex.en)
                        }
                        .padding(.top, 18)
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
        .onAppear { model.speakEnglish(item.phrase) }
    }
}

/// Colored tile with a patterned corner and the expression on a light label.
struct OptionTile: View {
    let text: String
    let style: PatternStyle
    var selected = false
    var state: OptionState = .idle
    let action: () -> Void

    enum OptionState { case idle, right, wrong, dimmed }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                ZStack {
                    style.fill
                    PatternFill(style: style).opacity(0.55).mask(
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    )
                }
                .clipShape(Radii.shape(style.rawValue))
                Text(text)
                    .font(WPFont.rubik(20, false))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Palette.cream.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 18)
                if state == .right || state == .wrong {
                    Image(systemName: state == .right ? "checkmark" : "xmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color(hex: 0xF4EDDC))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Palette.ink))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 14)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .overlay(Radii.shape(style.rawValue).stroke(Palette.outline, lineWidth: 2.5))
            .background(Radii.shape(style.rawValue).fill(Palette.outline).offset(x: selected ? 5 : 0, y: selected ? 5 : 0))
            .offset(x: selected ? -3 : 0, y: selected ? -3 : 0)
            .opacity(state == .dimmed ? 0.55 : 1)
            .animation(.easeOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(state == .right ? "верно" : state == .wrong ? "неверно" : "")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if step.retry {
                        Tag(text: "Ещё раз · с опорой", icon: "arrow.uturn.backward", fill: Palette.peach).padding(.top, 18)
                    }
                    ScreenTitle(text: "Выберите выражение", size: 29).padding(.top, 18)
                    Text(model.prefs.showTranslation ? item.recognition.promptRu : "Which expression means “\(item.meaningEn)”?")
                        .font(WPFont.nunito(19, .semibold))
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                    VStack(spacing: 16) {
                        ForEach(Array(options.enumerated()), id: \.element) { i, o in
                            OptionTile(text: o, style: .of(i), selected: picked == o && !checked, state: tileState(o)) {
                                if !checked { picked = o }
                            }
                            .disabled(checked)
                            if checked, o != item.phrase, let d = item.distractor(for: o) {
                                Text("\(o) — \(d.meaningRu)")
                                    .font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, -8)
                            }
                        }
                    }
                    .padding(.top, 26)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            if checked {
                FeedbackPanel(
                    title: correct ? "Верно!" : "Не совсем",
                    good: correct,
                    text: correct ? nil : wrongExplanation,
                    phrase: item.phrase,
                    meaning: model.prefs.showTranslation ? item.translationRu : item.meaningEn,
                    sentence: item.example?.en ?? item.gap.fullSentence,
                    translation: model.prefs.showTranslation ? (item.example?.ru ?? item.gap.translationRu) : nil,
                    highlight: item.phrase,
                    listen: { model.speakEnglish(item.example?.en ?? item.gap.fullSentence) },
                    next: { model.advance() }
                )
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
            if options.isEmpty { options = item.recognition.options.shuffled() }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-wpPickWrong") {
                picked = options.first { $0 != item.phrase }
                correct = model.answerRecognition(picked!)
                checked = true
            }
            #endif
        }
    }

    private var wrongExplanation: String? {
        guard let p = picked, let d = item.distractor(for: p) else { return nil }
        return d.explanationRu
    }

    private func tileState(_ o: String) -> OptionTile.OptionState {
        guard checked else { return .idle }
        if o == item.phrase { return .right }
        if o == picked { return .wrong }
        return .dimmed
    }
}

/// Result panel at the bottom: verdict, explanation, example with translation, "Дальше".
struct FeedbackPanel: View {
    let title: String
    let good: Bool
    var text: String?
    let phrase: String
    let meaning: String
    let sentence: String
    let translation: String?
    var highlight: String?
    let listen: () -> Void
    let next: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(WPFont.rubik(28)).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
            if let text {
                Text(text).font(WPFont.nunito(16)).fixedSize(horizontal: false, vertical: true)
            }
            (Text(phrase).font(WPFont.nunito(16, .heavy)) + Text(" — \(meaning)").font(WPFont.nunito(16)))
                .fixedSize(horizontal: false, vertical: true)
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
            PrimaryButtonInk(title: "Дальше", action: next).padding(.top, 6)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                (good ? PatternStyle.waves : PatternStyle.hatch).base
                PatternFill(style: good ? .waves : .hatch).opacity(0.35)
                    .clipShape(SideBlob(start: 0.8, variant: 1))
            }
            .clipShape(WobblyRect(variant: 3))
            .overlay(WobblyRect(variant: 3).stroke(Palette.outline, lineWidth: 2.5))
            .ignoresSafeArea(edges: .bottom)
        }
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
