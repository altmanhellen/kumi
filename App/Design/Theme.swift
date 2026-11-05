import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    /// A color that follows light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

/// Palette from the screen designs. Cards keep their colors in dark mode, only the outline turns light.
enum Palette {
    static let background = Color(light: 0xF4EDDC, dark: 0x1F1B18)
    static let text = Color(light: 0x1E1A16, dark: 0xF1E8D6)
    static let muted = Color(light: 0x645C52, dark: 0xA89D8C)
    static let secondary = Color(light: 0x3D3730, dark: 0xA89D8C)
    /// Box and list outlines. Quiet in dark mode, where bright cream is kept for emphasis.
    static let outline = Color(light: 0x1E1A16, dark: 0x7A7064)
    /// Outline of illustrated cards and the progress bar.
    static let cardOutline = Color(light: 0x1E1A16, dark: 0x5E554B)
    /// Outline of selected items.
    static let emphasis = Color(light: 0x1E1A16, dark: 0xF1E8D6)
    static let chevron = Color(light: 0x645C52, dark: 0x6B6157)
    static let track = Color(light: 0xFFFBF1, dark: 0x1F1B18)
    static let danger = Color(light: 0xB23A24, dark: 0xE8836E)
    static let paper = Color(light: 0xFFFBF1, dark: 0x2A2521)
    static let field = Color(light: 0xFFF8EA, dark: 0x2F2925)
    static let divider = Color(light: 0xCFC4AE, dark: 0x3A332D)
    static let navBorder = Color(light: 0x1E1A16, dark: 0x3A332D)
    static let primaryFill = Color(light: 0x1E1A16, dark: 0xF1E8D6)
    static let primaryText = Color(light: 0xF4EDDC, dark: 0x1E1A16)
    static let disabled = Color(light: 0x918A7F, dark: 0x6E665C)
    static let switchOff = Color(light: 0xE6DCC6, dark: 0x4A423B)

    /// Text on colored cards stays dark in both themes.
    static let ink = Color(hex: 0x1E1A16)
    static let inkSoft = Color(hex: 0x4A433B)
    static let cream = Color(hex: 0xFFF8EA)

    static let blue = Color(hex: 0x3A6FD0)
    static let teal = Color(hex: 0xBFE0DC)
    static let peach = Color(hex: 0xF7C3A2)
    static let yellow = Color(hex: 0xF9E08A)
    static let lilac = Color(hex: 0xD6C9F6)
    static let orange = Color(hex: 0xEE8A52)
    static let blush = Color(hex: 0xFADCC8)
    static let green = Color(hex: 0x5DBB6D)

    static func stateColor(_ s: LearningState) -> Color {
        switch s {
        case .mastered: green
        case .reviewing: Color(hex: 0x7FA7F0)
        case .learning: orange
        case .new: paper
        }
    }
}

enum WPFont {
    static func rubik(_ size: CGFloat, _ heavy: Bool = true, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(heavy ? "Rubik-ExtraBold" : "Rubik-Bold", size: size, relativeTo: style)
    }

    static func nunito(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case .heavy, .black: name = "Nunito-ExtraBold"
        case .bold: name = "Nunito-Bold"
        case .semibold, .medium: name = "Nunito-SemiBold"
        default: name = "Nunito-Regular"
        }
        return .custom(name, size: size, relativeTo: style)
    }

    static func handText(_ text: String) -> String { text }

    /// Names of blocks («Продолжить тему», «Выражение дня») and the Catalog kicker: Caveat Bold.
    static func label(_ size: CGFloat) -> Font {
        .custom("CaveatRoman-Bold", size: size, relativeTo: .headline)
    }

    /// Caveat's final «г» reaches past its advance width; a trailing no-break space gives it room.
    static func labelText(_ text: String) -> String { text + "\u{00A0}" }

    /// Small labels above titles and inside cards: Nunito Italic 400.
    /// 16pt on the welcome screen, 15pt for kickers, 14pt for labels inside cards.
    static func hand(_ size: CGFloat) -> Font {
        let pt: CGFloat = size >= 24 ? 16 : (size >= 22 ? 15 : 14)
        return .custom("NunitoItalic-Italic", size: pt, relativeTo: .subheadline)
    }
}

/// Uneven corner radii that give boxes the hand-cut look.
enum Radii {
    static let sets: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (12, 6, 10, 5), (6, 12, 5, 10), (10, 5, 12, 7), (5, 10, 7, 12), (9, 7, 5, 12), (7, 12, 9, 5),
    ]

    static func shape(_ i: Int) -> UnevenRoundedRectangle {
        let r = sets[abs(i) % sets.count]
        return UnevenRoundedRectangle(topLeadingRadius: r.0, bottomLeadingRadius: r.3, bottomTrailingRadius: r.2, topTrailingRadius: r.1)
    }
}

extension View {
    /// Thinner outlines in dark mode so the content, not the frames, carries the contrast.
    func outlineWidth(light: CGFloat, dark: CGFloat, _ body: @escaping (CGFloat) -> some View) -> some View {
        modifier(OutlineWidthReader(light: light, dark: dark, make: { AnyView(body($0)) }))
    }
}

struct OutlineWidthReader: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let light: CGFloat
    let dark: CGFloat
    let make: (CGFloat) -> AnyView
    func body(content: Content) -> some View {
        content.overlay(make(scheme == .dark ? dark : light))
    }
}

/// Quiet outline for paper boxes: 2.5pt ink in light mode, 1.5pt muted in dark mode.
struct BoxOutline<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let shape: S
    var color: Color = Palette.outline
    var light: CGFloat = 2.5
    var dark: CGFloat = 1.5
    func body(content: Content) -> some View {
        content.overlay(shape.stroke(color, lineWidth: scheme == .dark ? dark : light))
    }
}

extension View {
    func boxOutline<S: Shape>(_ shape: S) -> some View { modifier(BoxOutline(shape: shape)) }
    /// Solid colored boxes: ink outline in light mode, none in dark mode (color carries the shape).
    func fillOutline<S: Shape>(_ shape: S) -> some View {
        modifier(BoxOutline(shape: shape, color: Palette.ink, light: 2.5, dark: 0))
    }
    /// Outline of colored, illustrated cards: none in dark mode.
    func cardOutline<S: Shape>(_ shape: S) -> some View {
        modifier(BoxOutline(shape: shape, color: Palette.cardOutline, light: 2.5, dark: 0))
    }
}
