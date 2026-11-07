import SwiftUI

/// Beige onboarding (approved 6 Nov 2026): welcome, topics, one example card.

/// Black torn-edge call to action.
struct BeigeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(WPFont.rubik(20, false))
                Image(systemName: "arrow.right").font(.system(size: 19, weight: .bold))
            }
            .foregroundStyle(Palette.primaryText)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Palette.primaryFill)
            .clipShape(TornShape())
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// «Назад» and three progress segments.
struct BeigeProgress: View {
    let step: Int
    let back: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: back) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold))
                    Text("Назад").font(WPFont.nunito(16, .bold))
                }
                .foregroundStyle(Palette.text)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= step ? Color(hex: 0x2E5EFC) : Color(light: 0xDCD3C2, dark: 0x3A332D)).frame(height: 9)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Шаг \(step) из 3")
        }
        .padding(.top, 4)
    }
}

/// «Kumi» in M PLUS Rounded with the app colours, a divider and «English Collocations» in Caveat.
struct BeigeLogo: View {
    var body: some View {
        HStack(spacing: 14) {
            KumiWordmarkRounded(size: 56)
            Rectangle().fill(Palette.text.opacity(0.5)).frame(width: 1.5, height: 44)
            VStack(alignment: .leading, spacing: -4) {
                Text("English")
                Text(WPFont.labelText("Collocations"))
            }
            .font(.custom("CaveatRoman-Bold", size: 22, relativeTo: .headline))
            .foregroundStyle(Palette.secondary)
            .rotationEffect(.degrees(-3))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kumi, English Collocations")
    }
}

/// A card with an ink outline, uneven corners and a pattern strip on the right.
private struct StripCard<Content: View>: View {
    var fill: Color
    var pattern: OnbPattern
    var strip: CGFloat = 30
    var corners = 0
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.trailing, strip)
            .background(fill)
            .overlay(alignment: .trailing) {
                OnbPatternFill(pattern: pattern).frame(width: strip).clipShape(WavyStrip(amplitude: 4)).accessibilityHidden(true)
            }
            .clipShape(Radii.shape(corners))
            .modifier(BoxOutline(shape: Radii.shape(corners), color: Palette.cardOutline, light: 2.5, dark: 0))
    }
}

/// «Kumi» in M PLUS Rounded 1c Black with hand-set kerning and a round dot on the «i».
struct KumiWordmarkRounded: View {
    var size: CGFloat = 56

    var body: some View {
        let font = Font.custom("RoundedMplus1c-Black", fixedSize: size)
        let dot = size * 0.18
        HStack(spacing: 0) {
            Text("K").foregroundStyle(Color(hex: 0xFD7E34))
            Text("u").foregroundStyle(Color(hex: 0x2E5EFC)).padding(.leading, -0.08 * size)
            Text("m").foregroundStyle(Color(hex: 0x10CBDD)).padding(.leading, -0.065 * size)
            // Dotless «ı» with a circle whose top is level with the top of the K (font metrics: ascent 1.075 em, cap height 0.73 em).
            Text("\u{0131}").foregroundStyle(Color(hex: 0xC159FB))
                .overlay(alignment: .topLeading) {
                    Circle().fill(Color(hex: 0xC159FB)).frame(width: dot, height: dot)
                        .offset(x: 0.183 * size - dot / 2, y: (1.075 - 0.73) * size)
                }
                .padding(.leading, -0.085 * size)
        }
        .font(font)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kumi")
    }
}

// MARK: Screen 1

struct BeigeWelcome: View {
    let start: () -> Void
    let restore: () -> Void
    /// Short screens (SE, large text) tighten the gaps so the example phrases stay above the button.
    @State private var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BeigeLogo().padding(.top, compact ? 8 : 26)
                    Text(WPFont.labelText("Шаг 1 из 3")).font(WPFont.label(24)).foregroundStyle(Palette.secondary).padding(.top, compact ? 20 : 48)
                    Text("Говорите как").font(WPFont.rubik(36)).foregroundStyle(Palette.text).padding(.top, 2)
                    Text("носитель")
                        .font(WPFont.rubik(40))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .padding(.horizontal, 20).padding(.vertical, 4)
                        .background(Color(hex: 0xFDE156), in: TapeShape())
                        .rotationEffect(.degrees(-1.5))
                        .padding(.leading, -6)
                    Text("Запоминайте не отдельные слова, а сочетания, которые действительно используют в английском языке.")
                        .font(WPFont.nunito(17)).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16).padding(.trailing, 50)
                    chips.padding(.top, compact ? 18 : 28)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onGeometryChange(for: Bool.self) { $0.size.height < 600 } action: { compact = $0 }
            .background(alignment: .topTrailing) {
                OnbPatternFill(pattern: .waves)
                    .frame(width: 76, height: 220)
                    .clipShape(SideBlob(start: 0.15, variant: 1))
                    .offset(x: 12, y: 150)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 4) {
                BeigeButton(title: "Попробовать", action: start)
                LinkButton(title: "Уже занимались? Восстановить прогресс", action: restore)
            }
            .padding(.horizontal, 20).padding(.bottom, 8)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var chips: some View {
        let items: [(String, UInt32, Double)] = [
            ("heavy rain", 0xBDF0C4, -2), ("take a break", 0xFDC7BC, 1.5),
            ("grave concern", 0xCCB5FD, 1), ("keep a promise", 0xC8F2F7, -2),
        ]
        func chip(_ k: Int, _ size: CGFloat) -> some View {
            Text(items[k].0)
                .font(WPFont.rubik(size, false))
                .foregroundStyle(Palette.ink)
                .lineLimit(1).fixedSize()
                .padding(.horizontal, size < 18 ? 13 : 16).frame(minHeight: 44)
                .background(Color(hex: items[k].1), in: Capsule())
                .fillOutline(Capsule())
                .rotationEffect(.degrees(items[k].2))
        }
        // Two chips per row, smaller on narrow screens; one per row when the text is too large.
        return ViewThatFits(in: .horizontal) {
            ForEach([19, 16] as [CGFloat], id: \.self) { size in
                VStack(alignment: .leading, spacing: 12) {
                    ForEach([0, 2], id: \.self) { r in
                        HStack(spacing: 10) { ForEach(r..<r + 2, id: \.self) { chip($0, size) } }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) { ForEach(0..<4, id: \.self) { chip($0, 19) } }
        }
        .accessibilityHidden(true)
    }
}

// MARK: Screen 2

struct BeigeTopics: View {
    @Environment(AppModel.self) private var model
    let back: () -> Void
    let next: () -> Void
    @State private var selected: Set<String> = []

    static let topics: [(String, String, OnbPattern, UInt32)] = [
        ("Время и планы", "make a plan", .zigzag, 0xFFF2B3),
        ("Деньги и покупки", "make money", .hatch, 0xFECEC0),
        ("Здоровье и спорт", "keep fit", .dots, 0xFFF2B3),
        ("Общение и мнения", "make a phone call", .stripes, 0xCFB9FC),
        ("Общество и новости", "make a difference", .waves, 0xC7F5FA),
        ("Отношения и чувства", "make friends", .polka, 0xFECEC0),
    ]
    static let defaults: Set<String> = ["Деньги и покупки", "Здоровье и спорт", "Общество и новости"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BeigeProgress(step: 2, back: back).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Что вам интересно?").font(WPFont.rubik(30)).foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 18)
                    Text("Отметьте одну или несколько тем, с которых хотите начать. Вы сможете изменить выбор в любой момент.")
                        .font(WPFont.nunito(17)).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(Self.topics.enumerated()), id: \.element.0) { i, t in card(t, i) }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            BeigeButton(title: "Продолжить") {
                let picked = Self.topics.map(\.0).filter { selected.contains($0) }
                model.updatePrefs { $0.topics = picked.isEmpty ? Self.topics.map(\.0).filter { Self.defaults.contains($0) } : picked }
                next()
            }
            .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 8)
        }
        .screenBackground()
        .onAppear { selected = model.prefs.topics.isEmpty ? Self.defaults : Set(model.prefs.topics) }
    }

    private func card(_ t: (String, String, OnbPattern, UInt32), _ i: Int) -> some View {
        let on = selected.contains(t.0)
        return Button {
            if on { selected.remove(t.0) } else { selected.insert(t.0) }
        } label: {
            StripCard(fill: on ? Color(hex: t.3) : Palette.paper, pattern: t.2, strip: 26, corners: i) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Circle().fill(on ? Palette.ink : .clear)
                        Circle().stroke(on ? Palette.ink : Palette.text, lineWidth: 2)
                        if on { Image(systemName: "checkmark").font(.system(size: 12, weight: .black)).foregroundStyle(Palette.cream) }
                    }
                    .frame(width: 26, height: 26)
                    Spacer(minLength: 10)
                    Text(t.0).font(WPFont.rubik(16, false)).fixedSize(horizontal: false, vertical: true)
                    Text(t.1).font(WPFont.nunito(14.5)).lineLimit(1).minimumScaleFactor(0.85).padding(.top, 2)
                        .foregroundStyle(on ? Palette.inkSoft : Palette.muted)
                }
                .foregroundStyle(on ? Palette.ink : Palette.text)
                .padding(.leading, 14).padding(.vertical, 12).padding(.trailing, 8)
                .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            }
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("\(t.0), пример \(t.1), \(on ? "выбрано" : "не выбрано")")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: Screen 3

/// Always the same card: «run out of time».
struct BeigeExample: View {
    @Environment(AppModel.self) private var model
    let back: () -> Void
    let done: () -> Void

    private let phrase = "run out of time"
    private let example = "I ran out of time and didn’t finish the last question."

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BeigeProgress(step: 3, back: back).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Одно выражение — одна карточка").font(WPFont.rubik(30)).foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 18)
                    Text("Узнавайте значение, смотрите примеры и слушайте произношение.")
                        .font(WPFont.nunito(17)).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
                    card.padding(.top, 22)
                    exampleBox.padding(.top, 14)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            BeigeButton(title: "К занятиям", action: done)
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 8)
        }
        .screenBackground()
    }

    private var card: some View {
        StripCard(fill: Color(hex: 0xD9F1EE), pattern: .waves, strip: 34, corners: 1) {
            VStack(alignment: .leading, spacing: 0) {
                Text("B1 · Время и планы").font(WPFont.nunito(14, .heavy)).foregroundStyle(Palette.inkSoft)
                Text(phrase).font(WPFont.rubik(36)).fixedSize(horizontal: false, vertical: true).padding(.top, 6)
                Text("to have no more time left").font(WPFont.nunito(16, .semibold)).foregroundStyle(Palette.inkSoft).padding(.top, 6)
                Text("не хватить времени, время закончилось").font(WPFont.nunito(17, .bold))
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 2)
                HStack(spacing: 10) {
                    Button { model.speakEnglish(phrase) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill").font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Palette.cream)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Palette.ink))
                            Text("Слушать").font(WPFont.nunito(16, .heavy))
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel("Слушать \(phrase)")
                    Button { model.speakEnglish(phrase, slow: true) } label: {
                        Text("0.7×").font(WPFont.nunito(15, .heavy))
                            .padding(.horizontal, 12).frame(minHeight: 36)
                            .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel("Медленно")
                }
                .padding(.top, 14)
            }
            .foregroundStyle(Palette.ink)
            .padding(.leading, 20).padding(.vertical, 18).padding(.trailing, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var exampleBox: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(WPFont.labelText("Пример")).font(WPFont.label(22)).foregroundStyle(Palette.muted)
                Text(example).font(WPFont.nunito(17, .semibold)).foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("У меня закончилось время, и я не успел ответить на последний вопрос.")
                    .font(WPFont.nunito(15)).foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ListenButton(label: "Послушать пример", size: 44, fill: Palette.yellow) { model.speakEnglish(example) }
        }
        .padding(16)
        .background(Palette.paper, in: Radii.shape(3))
        .boxOutline(Radii.shape(3))
    }
}
