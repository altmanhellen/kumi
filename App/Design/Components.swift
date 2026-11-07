import SwiftUI

/// Card with a light base, a patterned blob on the right and a hand-drawn outline.
struct PatternCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var style: PatternStyle
    var variant = 0
    var blobStart: CGFloat = 0.7
    /// Keeps the content clear of the side pattern at any card width; the content then sets no trailing padding.
    var clearBlob = false
    @ViewBuilder var content: Content
    @State private var width: CGFloat = 0

    var body: some View {
        content
            // The blob edge wobbles up to 16 pt to the left of `blobStart`.
            .padding(.trailing, clearBlob ? width * (1 - blobStart) + 22 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .background {
                ZStack {
                    style.base
                    PatternFill(style: style).clipShape(SideBlob(start: blobStart, variant: variant))
                }
                .clipShape(WobblyRect(variant: variant))
                .accessibilityHidden(true)
            }
            .overlay {
                WobblyRect(variant: variant).stroke(Palette.cardOutline, style: StrokeStyle(lineWidth: scheme == .dark ? 0 : 2.5, lineJoin: .round))
            }
            .foregroundStyle(Palette.ink)
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled = true
    var height: CGFloat = 58
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WPFont.rubik(19, false, relativeTo: .headline))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 18)
                .foregroundStyle(enabled ? Palette.primaryText : Color(hex: 0xF4EDDC))
                .frame(maxWidth: .infinity, minHeight: height)
                .background(enabled ? Palette.primaryFill : Palette.disabled)
                .clipShape(TornShape())
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WPFont.nunito(15, .bold))
                .underline(true, pattern: .solid)
                .foregroundStyle(Palette.text)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
    }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

/// Round outlined button with a speaker icon.
struct ListenButton: View {
    let label: String
    var size: CGFloat = 44
    var fill: Color = Palette.yellow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(label)
    }
}

struct Eyebrow: View {
    let text: String
    var size: CGFloat = 23
    var body: some View {
        Text(WPFont.handText(text)).font(WPFont.hand(size)).foregroundStyle(Palette.muted)
    }
}

struct ScreenTitle: View {
    let text: String
    var size: CGFloat = 31
    var body: some View {
        Text(text)
            .font(WPFont.rubik(size))
            .foregroundStyle(Palette.text)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Bordered box used for settings groups and lists.
struct PaperBox<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var variant = 0
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Palette.paper, in: Radii.shape(variant))
            .overlay(Radii.shape(variant).stroke(Palette.outline, lineWidth: scheme == .dark ? 1.5 : 2.5))
    }
}

struct DashedDivider: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .overlay(Line().stroke(Palette.divider, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
            .padding(.horizontal, 14)
    }

    struct Line: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            return p
        }
    }
}

struct WPToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                ToggleTrack(isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// Switch track: ink outline in light mode, solid track without outline in dark mode.
struct ToggleTrack: View {
    @Environment(\.colorScheme) private var scheme
    let isOn: Bool

    var body: some View {
        let dark = scheme == .dark
        Capsule()
            .fill(isOn ? Palette.blue : Palette.switchOff)
            .frame(width: 52, height: 32)
            .overlay(Capsule().stroke(Palette.ink, lineWidth: dark ? 0 : 2.5))
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(dark ? Color(hex: 0xF1E8D6) : Color(hex: 0xFFFBF1))
                    .overlay(Circle().stroke(Palette.ink, lineWidth: dark ? 0 : 2))
                    .frame(width: 23, height: 23)
                    .padding(4.5)
            }
            .animation(.easeOut(duration: 0.15), value: isOn)
    }
}

/// Row with a title, optional subtitle, value and chevron.
struct SettingsRow: View {
    let title: String
    var subtitle: String?
    var value: String?
    var chevron = true

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(WPFont.nunito(16, .heavy)).foregroundStyle(Palette.text)
                if let subtitle { Text(subtitle).font(WPFont.nunito(14)).foregroundStyle(Palette.muted) }
            }
            Spacer(minLength: 8)
            if let value { Text(value).font(WPFont.nunito(15)).foregroundStyle(Palette.secondary).multilineTextAlignment(.trailing) }
            if chevron { Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.chevron) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

/// Bar with one segment per learning state.
struct StateBar: View {
    @Environment(\.colorScheme) private var scheme
    let counts: [LearningState: Int]
    let total: Int
    var height: CGFloat = 10
    /// On a light colored card the track stays cream; on a plain dark screen it goes dark and quiet.
    var onCard = true

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach([LearningState.mastered, .reviewing, .learning], id: \.self) { s in
                    let n = counts[s] ?? 0
                    if n > 0 && total > 0 {
                        // Each colored segment ends with a thin cream gap so neighbouring states stay apart.
                        Rectangle().fill(Palette.stateColor(s))
                            .frame(width: max(geo.size.width * CGFloat(n) / CGFloat(total), 6))
                            .overlay(alignment: .trailing) { Rectangle().fill(Color(hex: 0xFFFBF1)).frame(width: 1.5) }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: height)
        .background(onCard ? Color(hex: 0xFFFBF1) : Palette.track)
        .clipShape(RoundedRectangle(cornerRadius: height * 0.6))
        .overlay(RoundedRectangle(cornerRadius: height * 0.6)
            .stroke(onCard || scheme != .dark ? Palette.ink : Palette.outline, lineWidth: onCard || scheme != .dark ? 2 : 1.5))
        .accessibilityHidden(true)
    }
}

struct StatePill: View {
    @Environment(\.colorScheme) private var scheme
    let state: LearningState

    var body: some View {
        let dark = scheme == .dark
        Text(state.title)
            .font(WPFont.nunito(12, .heavy))
            .foregroundStyle(state == .new ? Palette.text : Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(state == .new ? Color.clear : Palette.stateColor(state), in: Capsule())
            .overlay(Capsule().stroke(state == .new ? Palette.outline : Palette.ink,
                                      style: StrokeStyle(lineWidth: state != .new && dark ? 0 : (dark ? 1.5 : 2), dash: state == .new ? [4, 3] : [])))
    }
}

struct LegendDot: View {
    let state: LearningState
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(state == .new ? Color(hex: 0xFFFBF1) : Palette.stateColor(state))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.ink, lineWidth: 2))
                .frame(width: 12, height: 12)
            Text("\(state.title) \(count)").font(WPFont.nunito(13, .bold)).foregroundStyle(Palette.text)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Bordered progress bar used at the top of a session.
struct SessionProgressBar: View {
    let value: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        GeometryReader { geo in
            Rectangle()
                .fill(Palette.blue)
                .frame(width: max(geo.size.width * value, value > 0 ? 6 : 0))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: value)
        }
        .frame(height: dark ? 10 : 14)
        .background(dark ? Color(hex: 0x3A332D) : Color(hex: 0xFFFBF1))
        .clipShape(RoundedRectangle(cornerRadius: dark ? 5 : 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Palette.ink, lineWidth: dark ? 0 : 2.5))
    }
}

struct Tag: View {
    let text: String
    var icon: String?
    var fill: Color = Palette.yellow

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
            Text(text).font(WPFont.nunito(13, .heavy))
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(fill, in: UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 10, bottomTrailingRadius: 14, topTrailingRadius: 10))
        .modifier(BoxOutline(shape: UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 10, bottomTrailingRadius: 14, topTrailingRadius: 10), color: Palette.ink, light: 2, dark: 0))
    }
}

/// Top bar of onboarding and session screens: back or close, progress, counter.
struct StepHeader<Progress: View>: View {
    let icon: String
    let label: String
    let action: () -> Void
    var counter: String?
    @ViewBuilder var progress: Progress

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(label)
            .padding(.leading, -10)
            progress.frame(maxWidth: .infinity)
            if let counter {
                Text(counter).font(WPFont.nunito(14, .bold)).foregroundStyle(Palette.muted).monospacedDigit()
            }
        }
        .frame(height: 44)
    }
}

struct OnboardingSteps: View {
    let current: Int
    let total = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(i < current ? Palette.blue : Color(hex: 0xFFFBF1))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.outline, lineWidth: 2))
                    .frame(height: 10)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Шаг \(current) из \(total)")
    }
}

/// Radio dot used in level and voice lists.
struct RadioDot: View {
    let on: Bool
    var body: some View {
        Circle()
            .fill(on ? Palette.blue : .clear)
            .overlay(Circle().stroke(Palette.teal, lineWidth: on ? 3 : 0).padding(2.5))
            .overlay(Circle().stroke(on ? Palette.ink : Palette.outline, lineWidth: 2.5))
            .frame(width: 22, height: 22)
    }
}

extension View {
    func screenBackground() -> some View {
        background(Palette.background.ignoresSafeArea())
    }

    /// Covers the status bar with the screen colour so scrolled content does not run under the clock.
    func statusBarBackdrop() -> some View {
        modifier(StatusBarBackdrop())
    }
}

/// Short labels in narrow tiles: one word per line, a word shrinks instead of breaking in the middle.
struct WordLines: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, w in
                Text(String(w)).lineLimit(1).minimumScaleFactor(0.6)
            }
        }
    }
}

/// Big title where one word sits on a yellow highlighter with three doodle strokes beside it.
struct HighlightTitle: View {
    let lead: String
    let mark: String
    var size: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lead).font(WPFont.rubik(size)).foregroundStyle(Palette.text)
            Text(mark)
                .font(WPFont.rubik(size + 4))
                .foregroundStyle(Palette.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 16).padding(.vertical, 1)
                .background(Color(hex: 0xF6CF47), in: Capsule())
                .rotationEffect(.degrees(-1.5))
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Main onboarding action: a solid yellow pill.
/// The main call to action: a coral strip of tape with torn ends and a soft glow.
struct CoralButton: View {
    let title: String
    var arrow = true
    var enabled = true
    var height: CGFloat = 62
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title).font(WPFont.rubik(22))
                if arrow { Image(systemName: "arrow.right").font(.system(size: 20, weight: .black)) }
            }
            .foregroundStyle(enabled ? Color(hex: 0xFFF6EA) : Palette.muted)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(enabled ? Color(hex: 0xFF6F5B) : Palette.disabled)
            .clipShape(TapeShape())
            .shadow(color: Color(hex: 0xFF6F5B).opacity(enabled ? 0.45 : 0), radius: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

/// Big Rubik phrase that shrinks until its longest word fits on one line, so words never break mid-word.
struct PhraseTitle: View {
    let text: String
    var size: CGFloat = 36
    @State private var width: CGFloat = 0

    var body: some View {
        Text(text)
            .font(WPFont.rubik(fittingSize))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private var fittingSize: CGFloat {
        guard width > 0 else { return size }
        let longest = text.components(separatedBy: " ").max { $0.count < $1.count } ?? text
        let scaled = UIFontMetrics(forTextStyle: .title1).scaledValue(for: size)
        guard let font = UIFont(name: "Rubik-ExtraBold", size: scaled) else { return size }
        let wordWidth = (longest as NSString).size(withAttributes: [.font: font]).width
        return wordWidth <= width ? size : max(size * width / wordWidth * 0.97, size * 0.6)
    }
}

/// A strip of the screen colour behind the status bar, as tall as the top safe area.
private struct StatusBarBackdrop: ViewModifier {
    @State private var top: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { top = $0 }
            .overlay(alignment: .top) {
                Palette.background
                    .frame(height: top)
                    .offset(y: -top)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}
