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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header.frame(maxWidth: .infinity).padding(.top, 14)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Говорите как").font(WPFont.rubik(36)).foregroundStyle(Palette.text)
                        HStack(spacing: 10) {
                            Text("носитель")
                                .font(WPFont.rubik(40))
                                .foregroundStyle(Palette.ink)
                                .padding(.horizontal, 18).padding(.vertical, 2)
                                .background(Color(hex: 0xF6CF47), in: Capsule())
                                .rotationEffect(.degrees(-1.5))
                            Sparks().frame(width: 30, height: 40)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 26)
                    .accessibilityElement(children: .combine)

                    Text("Учите слова парами и используйте естественные сочетания в речи.")
                        .font(WPFont.nunito(17)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)

                    mistakeCard.padding(.top, 28)

                    FlowChips(items: ["heavy rain", "take a break", "grave concern", "keep a promise"], outlined: false)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 26)
                }
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(i == 0 ? Color(hex: 0xF6CF47) : Palette.muted.opacity(0.5)).frame(width: 9, height: 9)
                }
            }
            .padding(.vertical, 12)
            .accessibilityHidden(true)

            Button(action: start) {
                ZStack {
                    Text("Начать").font(WPFont.rubik(22))
                    HStack { Spacer(); Image(systemName: "arrow.right").font(.system(size: 20, weight: .bold)) }
                        .padding(.trailing, 24)
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Color(hex: 0xF6CF47), in: RoundedRectangle(cornerRadius: 30))
            }
            .buttonStyle(PressStyle())
            LinkButton(title: "У меня уже есть прогресс — восстановить", action: restore).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 14) {
            KumiWordmark(size: 48)
            Rectangle().fill(Palette.muted.opacity(0.5)).frame(width: 1.5, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text("English")
                Text("Collocations")
            }
            .font(WPFont.rubik(16, false))
            .foregroundStyle(Palette.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var mistakeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Palette.blue)
                .rotationEffect(.degrees(-6))
                .offset(x: -12, y: 14)
            VStack(alignment: .leading, spacing: 6) {
                Text("do a mistake")
                    .font(WPFont.rubik(24, false))
                    .strikethrough(true, color: Color(hex: 0xE0533A))
                    .foregroundStyle(Palette.inkSoft.opacity(0.7))
                Text("make a mistake")
                    .font(WPFont.rubik(40))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 24).padding(.leading, 26).padding(.trailing, 110)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    PatternStyle.waves.base
                    PatternFill(style: .waves).clipShape(SideBlob(start: 0.7, variant: 1))
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .rotationEffect(.degrees(-1.5))
        }
        .padding(.horizontal, 4)
        .accessibilityElement()
        .accessibilityLabel("Не do a mistake, а make a mistake")
    }
}

/// Three short strokes beside the highlighted word, like a doodle.
struct Sparks: View {
    var body: some View {
        Canvas { ctx, size in
            let c = Color(hex: 0xF6CF47)
            let lines: [(CGPoint, CGPoint)] = [
                (CGPoint(x: 4, y: size.height * 0.2), CGPoint(x: size.width - 4, y: size.height * 0.05)),
                (CGPoint(x: 6, y: size.height * 0.5), CGPoint(x: size.width - 2, y: size.height * 0.5)),
                (CGPoint(x: 4, y: size.height * 0.8), CGPoint(x: size.width - 6, y: size.height * 0.98)),
            ]
            for (a, b) in lines {
                var p = Path(); p.move(to: a); p.addLine(to: b)
                ctx.stroke(p, with: .color(c), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

struct FlowChips: View {
    let items: [String]
    var outlined = true
    private let fills: [Color] = [Palette.yellow, Palette.peach, Palette.lilac, Palette.teal]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(stride(from: 0, to: items.count, by: 2).map { $0 }, id: \.self) { i in
                HStack(spacing: 8) {
                    ForEach(i..<min(i + 2, items.count), id: \.self) { k in
                        Text(items[k])
                            .font(WPFont.rubik(outlined ? 16 : 19, false))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, outlined ? 14 : 18).frame(minHeight: outlined ? 38 : 46)
                            .background(fills[k % fills.count], in: Capsule())
                            .modifier(BoxOutline(shape: Capsule(), color: Palette.ink, light: outlined ? 2.5 : 0, dark: 0))
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

/// The app name with each letter in one of the app's pattern colours.
struct KumiWordmark: View {
    var size: CGFloat = 52
    private let letters: [(String, Color)] = [
        ("K", Color(hex: 0xF07A3A)), ("u", Color(hex: 0x3A6FD0)), ("m", Color(hex: 0x2FA39A)), ("i", Color(hex: 0x9B6BE0)),
    ]

    var body: some View {
        letters.reduce(Text("")) { $0 + Text($1.0).foregroundColor($1.1) }
            .font(WPFont.rubik(size))
            .accessibilityLabel("Kumi")
    }
}
