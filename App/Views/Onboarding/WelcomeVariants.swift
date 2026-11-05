import SwiftUI

/// Prototypes of the first screen. Pick one with the launch argument -wpWelcome a|b|c.
enum WelcomeVariant: String { case quiz = "a", mistake = "b", deck = "c" }

/// A: a tiny game right away. Pick the verb that goes with «decision».
struct WelcomeQuiz: View {
    let start: () -> Void
    let restore: () -> Void
    @State private var picked: String?
    private let options = ["do", "make", "take"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Kumi").font(WPFont.rubik(22)).foregroundStyle(Palette.text).padding(.top, 24)
            Text("Проверим?").font(WPFont.label(30)).foregroundStyle(Palette.muted).padding(.top, 28)
            ScreenTitle(text: "Как сказать «принять решение»?", size: 32).padding(.top, 2)

            PatternCard(style: .dots, variant: 2, blobStart: 0.8) {
                HStack(spacing: 8) {
                    Text(picked ?? "___")
                        .font(WPFont.rubik(34))
                        .foregroundStyle(picked == nil ? Palette.inkSoft : (picked == "make" ? Color(hex: 0x2F7D4F) : Color(hex: 0xB23A24)))
                    Text("a decision").font(WPFont.rubik(34, false))
                }
                .padding(.vertical, 26).padding(.leading, 22).padding(.trailing, 70)
            }
            .padding(.top, 22)

            HStack(spacing: 10) {
                ForEach(options, id: \.self) { o in
                    Button { withAnimation(.spring(duration: 0.3)) { picked = o } } label: {
                        Text(o)
                            .font(WPFont.rubik(22, false))
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(fill(o), in: Radii.shape(o.count))
                            .fillOutline(Radii.shape(o.count))
                    }
                    .buttonStyle(PressStyle())
                }
            }
            .padding(.top, 16)

            Group {
                if picked == "make" {
                    Text("Да! Слова дружат парами: make a decision, а не do. Kumi учит 326 таких пар.")
                } else if picked != nil {
                    Text("Почти! По-английски — make a decision. Так ошибаются многие, и Kumi это исправит.")
                } else {
                    Text("Выберите слово — это займёт секунду.")
                }
            }
            .font(WPFont.nunito(17, .semibold))
            .foregroundStyle(Palette.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 18)

            Spacer()
            PrimaryButton(title: picked == nil ? "Пропустить и начать" : "Хочу так же · Начать", action: start)
            LinkButton(title: "У меня уже есть прогресс — восстановить", action: restore).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            #if DEBUG
            let a = ProcessInfo.processInfo.arguments
            if let i = a.firstIndex(of: "-wpPick"), i + 1 < a.count { picked = a[i + 1] }
            #endif
        }
    }

    private func fill(_ o: String) -> Color {
        guard let picked else { return Palette.paper }
        if o == "make" { return Color(hex: 0xD3EBD9) }
        return o == picked ? Color(hex: 0xF8D5CC) : Palette.paper
    }
}

/// B: the hook is a typical mistake, crossed out, with the right phrase under it.
struct WelcomeMistake: View {
    let start: () -> Void
    let restore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Kumi").font(WPFont.rubik(22)).foregroundStyle(Palette.text).padding(.top, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("do a mistake")
                    .font(WPFont.rubik(34, false))
                    .strikethrough(true, color: Color(hex: 0xC8452F))
                    .foregroundStyle(Palette.muted)
                    .rotationEffect(.degrees(-3))
                PatternCard(style: .waves, variant: 1, blobStart: 0.78) {
                    Text("make a mistake")
                        .font(WPFont.rubik(36))
                        .padding(.vertical, 22).padding(.leading, 22).padding(.trailing, 70)
                }
                .rotationEffect(.degrees(1.5))
            }
            .padding(.top, 40)

            ScreenTitle(text: "Говорите как носитель, а не как учебник", size: 30).padding(.top, 34)
            Text("Учите слова парами: make a decision, heavy rain, take a break. 3 минуты в день.")
                .font(WPFont.nunito(17)).foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            FlowChips(items: ["heavy rain", "take a break", "grave concern", "keep a promise"])
                .padding(.top, 20)

            Spacer()
            PrimaryButton(title: "Начать", action: start)
            LinkButton(title: "У меня уже есть прогресс — восстановить", action: restore).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct FlowChips: View {
    let items: [String]
    private let fills: [Color] = [Palette.yellow, Palette.peach, Palette.lilac, Palette.teal]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(stride(from: 0, to: items.count, by: 2).map { $0 }, id: \.self) { i in
                HStack(spacing: 8) {
                    ForEach(i..<min(i + 2, items.count), id: \.self) { k in
                        Text(items[k])
                            .font(WPFont.rubik(16, false))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 14).frame(minHeight: 38)
                            .background(fills[k % fills.count], in: Capsule())
                            .fillOutline(Capsule())
                            .rotationEffect(.degrees(k % 2 == 0 ? -2 : 2))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// C: a fanned deck of colourful phrase cards, very little text.
struct WelcomeDeck: View {
    let start: () -> Void
    let restore: () -> Void
    private let cards: [(String, PatternStyle, Double, CGFloat)] = [
        ("take a break", .stripes, -9, -28), ("heavy rain", .hatch, 6, 22), ("make a decision", .waves, -2, 0),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Kumi").font(WPFont.rubik(22)).foregroundStyle(Palette.text).padding(.top, 24)

            ZStack {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, c in
                    PatternCard(style: c.1, variant: i, blobStart: 0.74) {
                        Text(c.0).font(WPFont.rubik(28))
                            .padding(.vertical, 26).padding(.leading, 22).padding(.trailing, 60)
                    }
                    .frame(width: 300)
                    .rotationEffect(.degrees(c.2))
                    .offset(x: c.3, y: CGFloat(i - 1) * 74)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .padding(.top, 30)
            .accessibilityHidden(true)

            Text("Слова дружат парами").font(WPFont.label(30)).foregroundStyle(Palette.muted).padding(.top, 26)
            ScreenTitle(text: "326 фраз, которые звучат по-английски", size: 30).padding(.top, 2)

            Spacer()
            PrimaryButton(title: "Попробовать за 3 минуты", action: start)
            LinkButton(title: "У меня уже есть прогресс — восстановить", action: restore).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}
