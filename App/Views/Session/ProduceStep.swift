import SwiftUI

/// Type the whole expression into the gap, in the form the sentence needs.
struct ProduceStep: View {
    @Environment(AppModel.self) private var model
    let item: Collocation
    let step: SessionStep
    let initialDraft: String
    @State private var text = ""
    @State private var result: CheckResult?
    @FocusState private var focused: Bool

    private var hintShown: Bool { model.session?.hintShown ?? false }
    private var translationShown: Bool { model.session?.translationShown ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
            ScrollView {
                if let result {
                    ProductionFeedback(item: item, result: result, typed: text)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        if step.review {
                            Tag(text: "Повторение · подошёл срок", icon: "clock.arrow.circlepath", fill: Palette.yellow).padding(.top, 18)
                        } else if step.retry {
                            Tag(text: "Ещё раз", icon: "arrow.uturn.backward", fill: Palette.peach).padding(.top, 18)
                        }
                        ScreenTitle(text: step.review ? "Вспомните выражение" : "Впишите выражение целиком", size: 29).padding(.top, 14)
                        Text("Вспомните фразу самостоятельно.")
                            .font(WPFont.nunito(15)).foregroundStyle(Palette.muted).padding(.top, 4)

                        sentenceCard.padding(.top, 18)

                        Text(item.meaningEn)
                            .font(WPFont.nunito(15))
                            .foregroundStyle(Palette.muted)
                            .padding(.top, 12)
                            .padding(.horizontal, 2)

                        if translationShown {
                            Text(item.gap.hintRu)
                                .font(WPFont.nunito(15, .semibold))
                                .foregroundStyle(Palette.text)
                                .padding(.top, 4)
                                .padding(.horizontal, 2)
                        }

                        helpers.padding(.top, 12).id("tools")
                    }
                    .padding(.bottom, 12)
                }
            }
            .onChange(of: focused) { _, on in
                // Wait for the keyboard to finish resizing the screen, then bring the clues into view.
                guard on else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation { proxy.scrollTo("tools", anchor: .bottom) }
                }
            }
            .onChange(of: hintShown) { _, on in
                if on { withAnimation { proxy.scrollTo("tools", anchor: .bottom) } }
            }
            .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 20)

            if result != nil {
                PrimaryButton(title: "Дальше") { model.advance() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            } else {
                VStack(spacing: 2) {
                    PrimaryButton(title: "Проверить", enabled: !text.trimmingCharacters(in: .whitespaces).isEmpty) { check() }
                    LinkButton(title: "Не помню — показать ответ") {
                        result = model.answerProduction("", gaveUp: true)
                        focused = false
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
            }
        }
        .onAppear {
            text = initialDraft
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-wpFocus") {
                text = "raise"
                model.showHint()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
            }
            if let i = args.firstIndex(of: "-wpAnswer"), i + 1 < args.count {
                text = args[i + 1]
                check()
                return
            }
            #endif
        }
    }

    private var sentenceCard: some View {
        let parts = item.gap.parts
        return VStack(alignment: .leading, spacing: 6) {
            if !parts.before.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(parts.before.trimmingCharacters(in: .whitespaces)).font(WPFont.nunito(21, .semibold))
            }
            if hintShown {
                Text("Первые буквы: \(AnswerChecker.firstLettersHint(item.gap.answer))")
                    .font(WPFont.nunito(16, .bold)).foregroundStyle(Palette.inkSoft)
                    .accessibilityLabel("Подсказка: первые буквы \(item.gap.answer.split(separator: " ").compactMap(\.first).map(String.init).joined(separator: ", "))")
            }
            TextField("", text: $text, prompt: Text(hintShown ? AnswerChecker.firstLettersHint(item.gap.answer) : "…").foregroundStyle(Palette.inkSoft.opacity(0.7)))
                .font(WPFont.rubik(22, false))
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.done)
                .focused($focused)
                .disabled(result != nil)
                .onSubmit { if !text.trimmingCharacters(in: .whitespaces).isEmpty { check() } }
                .onChange(of: text) { _, v in model.setDraft(v) }
                .padding(.horizontal, 10)
                .frame(height: 46)
                .background(Palette.cream, in: UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6))
                .overlay(alignment: .bottom) {
                    DashedDivider.Line().stroke(Palette.ink, style: StrokeStyle(lineWidth: 3, dash: [7, 5])).frame(height: 3)
                }
                .accessibilityLabel("Пропущенное выражение")
                .accessibilityHint(item.gap.sentence.replacingOccurrences(of: "___", with: "пропуск"))
            if !parts.after.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(parts.after.trimmingCharacters(in: .whitespaces)).font(WPFont.nunito(21, .semibold))
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 22).padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                PatternStyle.dots.base
                PatternFill(style: .dots).clipShape(SideBlob(start: 0.86, variant: 1))
            }
            .clipShape(WobblyRect(variant: 2))
        }
        .cardOutline(WobblyRect(variant: 2))
    }

    /// Two small buttons under the meaning: show the translation, show the first letters.
    private var helpers: some View {
        HStack(spacing: 10) {
            if model.prefs.showTranslation {
                toolButton("Перевод", icon: translationShown ? "eye" : "eye.slash", done: translationShown) {
                    model.showTranslation()
                }
            }
            toolButton("Подсказка", icon: "lightbulb", done: hintShown) { model.showHint() }
                .accessibilityHint("Покажет первые буквы. Ответ с подсказкой засчитывается как трудный")
        }
    }

    private func toolButton(_ title: String, icon: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(title).font(WPFont.nunito(15, .heavy))
            }
            .foregroundStyle(done ? Palette.muted : Palette.text)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Palette.paper, in: Capsule())
            .boxOutline(Capsule())
        }
        .buttonStyle(PressStyle())
        .disabled(done)
    }

    private func check() {
        result = model.answerProduction(text)
        focused = false
    }
}

struct ProductionFeedback: View {
    @Environment(AppModel.self) private var model
    let item: Collocation
    let result: CheckResult
    let typed: String

    private var title: String {
        switch result.verdict {
        case .correct: "Верно!"
        case .typoAccepted: "Верно, но с опечаткой"
        case .spelling: "Выражение верное, написание нет"
        case .distractor: "Другое выражение"
        case .wrong: typed.isEmpty ? "Ответ" : "Не совсем"
        }
    }

    private var note: String? {
        switch result.verdict {
        case .distractor(let d): d.explanationRu
        case .spelling: "С уровня B2 засчитываем только точное написание."
        case .typoAccepted: "Засчитали, но проверьте написание."
        default: nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FeedbackCard(
                title: title,
                good: result.verdict.isCorrect,
                text: note,
                phrase: nil,
                meaning: nil,
                sentence: item.gap.fullSentence,
                translation: model.prefs.showTranslation ? item.gap.translationRu : nil,
                highlight: item.gap.answer,
                listen: { model.speakEnglish(item.gap.fullSentence) }
            ) {
                if !typed.isEmpty && result.verdict != .correct { yourAnswer }
            }
            (Text(item.phrase).font(WPFont.nunito(16, .heavy)) + Text(" — \(model.prefs.showTranslation ? item.translationRu : item.meaningEn)").font(WPFont.nunito(16)))
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
            if !result.verdict.isCorrect {
                Text("Вернёмся к нему позже в этом занятии.").font(WPFont.nunito(14, .bold)).foregroundStyle(Palette.muted)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var yourAnswer: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text("Ваш ответ:").font(WPFont.nunito(15))
                ForEach(Array(result.marks.enumerated()), id: \.offset) { _, m in
                    Text(m.word)
                        .font(WPFont.nunito(15, .heavy))
                        .strikethrough(!m.ok, color: Color(hex: 0xC2412D))
                        .foregroundStyle(m.ok ? Palette.ink : Color(hex: 0xA3311F))
                }
            }
            HStack(spacing: 4) {
                Text("Верно:").font(WPFont.nunito(15))
                Text(result.target).font(WPFont.nunito(15, .heavy))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
