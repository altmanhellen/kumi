import SwiftUI

/// Onboarding in the Kumi style: bright patterned cards on a dark or cream background.
enum Onb {
    /// Dark value first, light second; follows the system appearance.
    static func dyn(_ dark: UInt32, _ light: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }
    static let bg = dyn(0x17171C, 0xFAF6EF)
    static let text = dyn(0xF5F3F8, 0x16151A)
    static let body = dyn(0xB9B7C2, 0x5A5762)
    static let secondary = body
    static let card = dyn(0x24242B, 0xFFFFFF)
    static let line = dyn(0x8A8A92, 0xD3CDC2)
    static let barEmpty = dyn(0xF4F2F7, 0xE5DFD4)
    /// Main button colour; Elena is still choosing between this, yellow and the old gradient.
    static let cta = Color(hex: 0xD81159)

    static func pastel(_ hex: UInt32) -> Color { Color(hex: hex) }

    /// A tone darker than the card, for the topic pill on it.
    static func pillTone(_ hex: UInt32) -> Color {
        switch hex {
        case 0xFECEC0: Color(hex: 0xFBAA94)
        case 0xFFF2B3: Color(hex: 0xFCDD5E)
        case 0xC7F5FA: Color(hex: 0x8FE3EE)
        case 0xCFB9FC: Color(hex: 0xB596F8)
        case 0xFFE4DD: Color(hex: 0xFDBFAF)
        default: Color(hex: hex)
        }
    }

    /// Pale yellow cards get a darker yellow edge on cream so they do not blend in.
    static func pastelEdge(_ hex: UInt32) -> Color {
        hex == 0xFFF2B3 ? Color(UIColor { $0.userInterfaceStyle == .dark ? .clear : UIColor(Color(hex: 0xE3BE2E)) }) : .clear
    }
    static let blue = Color(hex: 0x1D56FD)
    static let bar = Color(hex: 0x2E5EFC)
    static let ink = Color(hex: 0x111114)

    /// Onboarding headings: Montserrat ExtraBold.
    static func h1(_ size: CGFloat = 34) -> Font { .custom("Montserrat-ExtraBold", size: size, relativeTo: .title) }
    static func body(_ size: CGFloat = 17) -> Font { WPFont.nunito(size, relativeTo: .body) }
}

/// Full-width flat call to action, no glow.
struct OnbButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon { Image(systemName: icon).font(.system(size: 18, weight: .bold)) }
                Text(title).font(.custom("Montserrat-Bold", size: 17, relativeTo: .headline))
                if icon == nil { Image(systemName: "arrow.right").font(.system(size: 20, weight: .bold)) }
            }
            .foregroundStyle(.white)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Onb.cta, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(PressStyle())
    }
}

struct OnbLink: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(WPFont.nunito(16, .bold)).underline().foregroundStyle(Onb.text).frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

/// Back chevron, three bars and «N из 3».
struct OnbProgress: View {
    let step: Int
    let back: () -> Void
    var body: some View {
        HStack(spacing: 6) {
            Button(action: back) {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundStyle(Onb.text)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .accessibilityLabel("Назад")
            ForEach(1...3, id: \.self) { i in
                Capsule().fill(i <= step ? Onb.bar : Onb.barEmpty).frame(height: 10)
            }
            Text("\(step) из 3").font(WPFont.nunito(17, .semibold)).foregroundStyle(Onb.text).padding(.leading, 8)
                .fixedSize()
        }
        .padding(.top, 6)
        .accessibilityElement(children: .contain)
    }
}

/// Small handwritten label above a heading.
struct OnbHand: View {
    let text: String
    var size: CGFloat = 24
    var body: some View {
        Text(WPFont.labelText(text)).font(WPFont.label(size)).foregroundStyle(Onb.body)
    }
}

/// Colour Kumi wordmark, a thin divider and «English Collocations» in Caveat.
struct KumiLogo: View {
    var size: CGFloat = 54
    var label: CGFloat = 22

    var body: some View {
        HStack(spacing: size * 0.26) {
            [("K", Color(hex: 0xFD7E34)), ("u", Color(hex: 0x2E5EFC)), ("m", Onb.dyn(0x15DEE9, 0x10B9CB)), ("i", Color(hex: 0xC159FB))]
                .reduce(Text("")) { $0 + Text($1.0).foregroundColor($1.1) }
                .font(.custom("Nunito-ExtraBold", size: size))
            Rectangle().fill(Onb.line).frame(width: 1.5, height: size * 0.8)
            VStack(alignment: .leading, spacing: -4) {
                Text("English")
                Text(WPFont.labelText("Collocations"))
            }
            .font(WPFont.label(label))
            .foregroundStyle(Onb.body)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kumi, English Collocations")
    }
}

// MARK: Patterns

enum OnbPattern {
    case waves, hatch, dots, stripes, polka, zigzag, plain(Color)

    var base: Color {
        switch self {
        case .waves: Color(hex: 0x2CD1F1)
        case .hatch: Color(hex: 0xFA8A48)
        case .dots, .zigzag: Color(hex: 0xFDDF53)
        case .stripes: Color(hex: 0xA77BF5)
        case .polka: Color(hex: 0xFEC7BB)
        case .plain(let c): c
        }
    }
}

struct OnbPatternFill: View {
    let pattern: OnbPattern
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(pattern.base))
            switch pattern {
            case .waves:
                var y: CGFloat = 12
                while y < size.height + 10 {
                    var p = Path(); var x: CGFloat = -8
                    p.move(to: CGPoint(x: x, y: y))
                    while x < size.width + 16 {
                        p.addQuadCurve(to: CGPoint(x: x + 16, y: y), control: CGPoint(x: x + 8, y: y - 9))
                        p.addQuadCurve(to: CGPoint(x: x + 32, y: y), control: CGPoint(x: x + 24, y: y + 9))
                        x += 32
                    }
                    ctx.stroke(p, with: .color(Onb.blue), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    y += 24
                }
            case .hatch:
                var p = Path(); var x: CGFloat = -size.height
                while x < size.width + size.height {
                    p.move(to: CGPoint(x: x, y: size.height)); p.addLine(to: CGPoint(x: x + size.height * 0.5, y: 0))
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x + size.height * 0.5, y: size.height))
                    x += 30
                }
                ctx.stroke(p, with: .color(Color(hex: 0xE5482E)), lineWidth: 2.5)
            case .dots:
                var rng = SplitMix64(seed: 11)
                for _ in 0..<max(Int(size.width * size.height / 420), 6) {
                    let x = CGFloat(rng.next() % 1000) / 1000 * size.width
                    let y = CGFloat(rng.next() % 1000) / 1000 * size.height
                    let r = 3 + CGFloat(rng.next() % 6)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0x2E5EFC)))
                }
            case .stripes:
                var y: CGFloat = 10
                while y < size.height + 10 {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 6)), with: .color(Color(hex: 0xF0619A)))
                    y += 22
                }
            case .polka:
                var row = 0; var y: CGFloat = 10
                while y < size.height + 10 {
                    var x: CGFloat = row % 2 == 0 ? 8 : 20
                    while x < size.width + 10 {
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(Color(hex: 0xF0329A)))
                        x += 24
                    }
                    y += 20; row += 1
                }
            case .zigzag:
                var y: CGFloat = 12
                while y < size.height + 10 {
                    var p = Path(); var x: CGFloat = -6; var up = true
                    p.move(to: CGPoint(x: x, y: y))
                    while x < size.width + 8 { x += 7; p.addLine(to: CGPoint(x: x, y: y + (up ? -6 : 0))); up.toggle() }
                    ctx.stroke(p, with: .color(Color(hex: 0xF0A81E)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    y += 18
                }
            case .plain: break
            }
        }
    }
}

/// Right-hand strip with a wavy left edge.
struct WavyStrip: Shape {
    var amplitude: CGFloat = 5
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + amplitude, y: r.minY))
        let n = 3
        let step = r.height / CGFloat(n)
        for i in 0..<n {
            let y0 = r.minY + CGFloat(i) * step
            p.addCurve(to: CGPoint(x: r.minX + amplitude, y: y0 + step),
                       control1: CGPoint(x: r.minX - amplitude, y: y0 + step * 0.33),
                       control2: CGPoint(x: r.minX + amplitude * 3, y: y0 + step * 0.66))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A plate with soft wavy top and bottom edges and straight sides.
struct WavyPlate: Shape {
    var waves = 16
    var amplitude: CGFloat = 3
    func path(in r: CGRect) -> Path {
        let a = amplitude, step = r.width / CGFloat(waves)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + a))
        for i in 0..<waves {
            let x = r.minX + CGFloat(i) * step
            p.addQuadCurve(to: CGPoint(x: x + step, y: r.minY + a), control: CGPoint(x: x + step / 2, y: r.minY + (i % 2 == 0 ? -a : 3 * a)))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - a))
        for i in 0..<waves {
            let x = r.maxX - CGFloat(i) * step
            p.addQuadCurve(to: CGPoint(x: x - step, y: r.maxY - a), control: CGPoint(x: x - step / 2, y: r.maxY + (i % 2 == 0 ? a : -3 * a)))
        }
        p.closeSubpath()
        return p
    }
}

// MARK: Welcome

struct OnbWelcome: View {
    let start: () -> Void
    let restore: () -> Void
    /// Variant B of the headline: «Английский, который звучит естественно».
    var natural = ProcessInfo.processInfo.arguments.contains("-wpNatural")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    logo.padding(.top, 30)
                    OnbHand(text: "Шаг 1 из 3").padding(.top, 52)
                    Text(natural ? "Английский,\nкоторый звучит" : "Говорите как").font(Onb.h1(natural ? 28 : 34)).foregroundStyle(Onb.text)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 2)
                    HStack(spacing: 10) {
                        Text(natural ? "естественно" : "носитель")
                            .font(Onb.h1(natural ? 32 : 38))
                            .foregroundStyle(Onb.ink)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 20).padding(.vertical, 4)
                            .background(Color(hex: 0xFDE156), in: TapeShape())
                            .rotationEffect(.degrees(-1.5))
                    }
                    Text(natural ? "Учите слова парами — так, как их сочетают носители." : "Учите слова парами и используйте естественные сочетания в речи.")
                        .font(Onb.body(17.5)).foregroundStyle(Onb.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14).padding(.trailing, 60)
                    chips.padding(.top, 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(alignment: .topTrailing) {
                OnbPatternFill(pattern: .waves)
                    .frame(width: 58, height: 230)
                    .clipShape(WavyStrip(amplitude: 6))
                    .rotationEffect(.degrees(-3))
                    .offset(x: 8, y: 150)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 6) {
                OnbButton(title: "Попробовать", action: start)
                OnbLink(title: "У меня уже есть прогресс — восстановить", action: restore)
            }
            .padding(.horizontal, 20).padding(.bottom, 8)
        }
        .background(Onb.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var logo: some View { KumiLogo() }

    private var chips: some View {
        let items: [(String, UInt32, Double)] = [
            ("heavy rain", 0xBDF0C4, -2), ("take a break", 0xFDC7BC, -1),
            ("grave concern", 0xCCB5FD, -3), ("keep a promise", 0xC8F2F7, 0),
        ]
        func chip(_ k: Int, _ size: CGFloat = 19) -> some View {
            Text(items[k].0)
                .font(WPFont.nunito(size, .heavy))
                .foregroundStyle(Onb.ink)
                .lineLimit(1).fixedSize()
                .padding(.horizontal, size < 19 ? 13 : 16).frame(minHeight: 44)
                .background(Color(hex: items[k].1), in: Capsule())
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
            VStack(alignment: .leading, spacing: 12) { ForEach(0..<4, id: \.self) { chip($0) } }
        }
        .accessibilityHidden(true)
    }
}

private struct Line: Shape {
    func path(in r: CGRect) -> Path { var p = Path(); p.move(to: CGPoint(x: 0, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)); return p }
}

// MARK: Topics

struct OnbTopics: View {
    @Environment(AppModel.self) private var model
    let back: () -> Void
    let next: () -> Void
    @State private var selected: Set<String> = []

    static let topics: [(String, String, OnbPattern, UInt32)] = [
        ("Время и планы", "make a plan", .zigzag, 0xFFF2B3),
        ("Деньги и покупки", "make money", .hatch, 0xFECEC0),
        ("Здоровье и спорт", "do exercise", .dots, 0xFFF2B3),
        ("Общение и мнения", "make a phone call", .stripes, 0xCFB9FC),
        ("Общество и новости", "make a difference", .waves, 0xC7F5FA),
        ("Отношения и чувства", "make friends", .hatch, 0xFECEC0),
        ("Повседневная жизнь", "do the housework", .polka, 0xFFE4DD),
        ("Путешествия", "go on a trip", .waves, 0xC7F5FA),
    ]

    /// Used when nothing is picked.
    static let defaults = ["Деньги и покупки", "Здоровье и спорт", "Общество и новости"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnbProgress(step: 2, back: back).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Что вам интересно?").font(Onb.h1(29)).foregroundStyle(Onb.text)
                        .minimumScaleFactor(0.8).lineLimit(2).padding(.top, 22)
                    Text("Отметьте одну или несколько тем — с них начнутся рекомендации. Другие темы можно открыть в любой момент.")
                        .font(Onb.body(17)).foregroundStyle(Onb.body)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 8)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Self.topics, id: \.0) { t in card(t) }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            OnbButton(title: "Продолжить") {
                let picked = Self.topics.map(\.0).filter { selected.contains($0) }
                model.updatePrefs { p in p.topics = picked.isEmpty ? Self.defaults : picked }
                next()
            }
            .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 8)
        }
        .background(Onb.bg.ignoresSafeArea())
        .onAppear { selected = Set(model.prefs.topics) }
    }

    private func card(_ t: (String, String, OnbPattern, UInt32)) -> some View {
        let on = selected.contains(t.0)
        return Button {
            if on { selected.remove(t.0) } else { selected.insert(t.0) }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle().fill(on ? Onb.ink : .clear)
                    Circle().stroke(on ? Onb.ink : Onb.text, lineWidth: 2)
                    if on { Image(systemName: "checkmark").font(.system(size: 12, weight: .black)).foregroundStyle(.white) }
                }
                .frame(width: 28, height: 28)
                Spacer(minLength: 10)
                Text(t.0).font(WPFont.nunito(16, .heavy)).fixedSize(horizontal: false, vertical: true)
                Text(t.1).font(Onb.body(14.5)).lineLimit(1).minimumScaleFactor(0.85).padding(.top, 2)
                    .foregroundStyle(on ? Color(hex: 0x3A3A40) : Onb.secondary)
            }
            .foregroundStyle(on ? Onb.ink : Onb.text)
            .padding(.leading, 14).padding(.vertical, 12).padding(.trailing, Self.stripWidth(t.2) + 8)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(on ? Onb.pastel(t.3) : Onb.card)
            .overlay(alignment: .trailing) {
                OnbPatternFill(pattern: t.2).frame(width: Self.stripWidth(t.2)).clipShape(WavyStrip(amplitude: 4)).accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(on ? Onb.pastelEdge(t.3) : Onb.line, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("\(t.0), пример \(t.1), \(on ? "выбрано" : "не выбрано")")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    static func stripWidth(_ p: OnbPattern) -> CGFloat {
        if case .zigzag = p { return 20 }
        return 30
    }

    static func style(of topic: String) -> (OnbPattern, UInt32) {
        let t = topics.first { $0.0 == topic } ?? topics[0]
        return (t.2, t.3)
    }
}

// MARK: First card

/// «Вот как это работает»: three real expressions from the picked topics, translation shown right away.
struct OnbFirstCard: View {
    @Environment(AppModel.self) private var model
    let back: () -> Void
    let done: () -> Void
    @State private var page = 0

    /// Picked topics in on-screen order.
    private var topics: [String] {
        let t = OnbTopics.topics.map(\.0).filter { model.prefs.topics.contains($0) }
        return t.isEmpty ? OnbTopics.defaults : t
    }

    /// One phrase per topic, round-robin until there are three: the user's level first, then lower levels.
    private var slides: [(String, Collocation)] {
        let levels = Array(Level.allCases.filter { $0 <= model.prefs.level }.reversed())
        let pools = topics.map { t in
            levels.flatMap { l in model.library.items.filter { $0.topics.contains(t) && $0.level == l } }
        }
        var out: [(String, Collocation)] = []
        var used = Set<String>()
        var round = 0
        while out.count < 3 && round < 10 {
            for (k, t) in topics.enumerated() where out.count < 3 {
                if let c = pools[k].filter({ !used.contains($0.id) }).first {
                    out.append((t, c)); used.insert(c.id)
                }
            }
            round += 1
        }
        return out
    }

    var body: some View {
        let slides = self.slides
        VStack(alignment: .leading, spacing: 0) {
            OnbProgress(step: 3, back: back).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Вот как это работает").font(Onb.h1(29)).foregroundStyle(Onb.text)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 18)
                    Text("Изучайте полезные сочетания, слушайте произношение и смотрите примеры.")
                        .font(Onb.body(16.5)).foregroundStyle(Onb.secondary)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
                    TabView(selection: $page) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { i, s in
                            slide(s.0, s.1, index: i, count: slides.count).tag(i).padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 380)
                    .padding(.horizontal, -20)
                    .padding(.top, 18)
                    dots(slides.count)
                }
                .padding(.horizontal, 20).padding(.bottom, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            OnbButton(title: "Начать", action: done)
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 12)
        }
        .background(Onb.bg.ignoresSafeArea())
        #if DEBUG
        .onAppear {
            let a = ProcessInfo.processInfo.arguments
            if let i = a.firstIndex(of: "-wpPage"), i + 1 < a.count { page = Int(a[i + 1]) ?? 0 }
        }
        #endif
    }

    private func go(_ i: Int) {
        withAnimation(UIAccessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: 0.25)) { page = i }
    }

    private func dots(_ count: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                Button { go(i) } label: {
                    Circle().fill(i == page ? Onb.bar : Color(hex: 0x6C6A75)).frame(width: 10, height: 10)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Пример \(i + 1) из \(count)")
                .accessibilityAddTraits(i == page ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func slide(_ topic: String, _ item: Collocation, index: Int, count: Int) -> some View {
        VStack(spacing: 14) {
            card(topic, item).onTapGesture { go((index + 1) % count) }
            if let ex = item.example { example(ex.en, phrase: item.phrase) }
            Spacer(minLength: 0)
        }
    }

    private func card(_ topic: String, _ item: Collocation) -> some View {
        let (pattern, fill) = OnbTopics.style(of: topic)
        let strip: CGFloat = 35
        return VStack(alignment: .leading, spacing: 0) {
            Text(topic).font(WPFont.nunito(14, .heavy)).foregroundStyle(Onb.ink)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Onb.pillTone(fill), in: Capsule())
            Text(item.phrase).font(Onb.h1(31)).lineLimit(2).minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Spacer(minLength: 10)
            Text(item.translationRu).font(WPFont.nunito(18, .bold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 30)
        }
        .foregroundStyle(Onb.ink)
        .padding(.leading, 20).padding(.vertical, 18).padding(.trailing, strip + 6)
        .frame(maxWidth: .infinity, minHeight: 206, alignment: .topLeading)
        .background(Onb.pastel(fill))
        .overlay(alignment: .trailing) {
            OnbPatternFill(pattern: pattern).frame(width: strip).clipShape(WavyStrip(amplitude: 4)).accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Onb.pastelEdge(fill), lineWidth: 1.5))
        .overlay(alignment: .bottomTrailing) {
            Button { model.speakEnglish(item.phrase) } label: {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Onb.pastel(fill))
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Onb.ink))
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("Послушать \(item.phrase)")
            .padding(.trailing, 14).padding(.bottom, 14)
        }
        .accessibilityElement(children: .contain)
    }

    private func example(_ text: String, phrase: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\u{201C}").font(Onb.h1(44)).foregroundStyle(Color(hex: 0xCFB9FC)).frame(height: 34, alignment: .top)
                .accessibilityHidden(true)
            Text(highlighted(text, phrase: phrase)).font(WPFont.nunito(18)).foregroundStyle(Onb.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Onb.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Onb.line, lineWidth: 1.5))
    }

    /// The example with the collocation on a lilac highlight, kept on one line.
    private func highlighted(_ text: String, phrase: String) -> AttributedString {
        // Each word may change its ending: make money → makes money, made money.
        let pattern = phrase.split(separator: " ").map { w in
            NSRegularExpression.escapedPattern(for: String(w.prefix(max(2, w.count - 2)))) + "\\w*"
        }.joined(separator: "\\s+(?:\\w+\\s+){0,4}?")
        guard let r = text.range(of: "\\b" + pattern, options: [.regularExpression, .caseInsensitive]) else { return AttributedString(text) }
        var mark = AttributedString("\u{2009}" + text[r].replacingOccurrences(of: " ", with: "\u{00A0}") + "\u{2009}")
        mark.backgroundColor = Color(hex: 0xCFB9FC)
        mark.foregroundColor = Onb.ink
        mark.font = WPFont.nunito(18, .heavy)
        return AttributedString(String(text[..<r.lowerBound])) + mark + AttributedString(String(text[r.upperBound...]))
    }
}
