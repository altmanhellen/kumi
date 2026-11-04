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
                        Text("Без вариантов: вспомните фразу сами. \(item.gap.answerWordCount) \(Plural.form(item.gap.answerWordCount, "слово", "слова", "слов")).")
                            .font(WPFont.nunito(15)).foregroundStyle(Palette.muted).padding(.top, 4)

                        sentenceCard.padding(.top, 20)

                        Text(item.meaningEn)
                            .font(WPFont.nunito(15))
                            .foregroundStyle(Palette.muted)
                            .padding(.top, 12)
                            .padding(.horizontal, 2)

                        helpers.padding(.top, 12)
                    }
                    .padding(.bottom, 12)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
            if hintShown {
                Text("Подсказка: \(AnswerChecker.firstLettersHint(item.gap.answer))")
                    .font(WPFont.nunito(14, .bold)).foregroundStyle(Palette.inkSoft).padding(.top, 2)
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

    @ViewBuilder
    private var helpers: some View {
        if model.prefs.showTranslation {
            HStack(spacing: 10) {
                Image(systemName: translationShown ? "eye" : "eye.slash").font(.system(size: 15, weight: .semibold))
                Text(translationShown ? item.gap.hintRu : "Перевод скрыт до ответа")
                    .font(WPFont.nunito(15)).foregroundStyle(Palette.muted)
                Spacer()
                if !translationShown {
                    Button("Показать") { model.showTranslation() }
                        .font(WPFont.nunito(15, .heavy)).underline().foregroundStyle(Palette.text).frame(minHeight: 40)
                }
            }
            .foregroundStyle(Palette.muted)
            .padding(.leading, 14).padding(.trailing, 8)
            .frame(minHeight: 48)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.muted, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        }
        if !hintShown {
            Button { model.showHint() } label: {
                Text("Подсказка: первые буквы")
                    .font(WPFont.nunito(15, .heavy))
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Palette.paper, in: Capsule())
                    .boxOutline(Capsule())
            }
            .buttonStyle(PressStyle())
            .padding(.top, 12)
            .accessibilityHint("Ответ с подсказкой засчитывается как трудный")
        }
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
