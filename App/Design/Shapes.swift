import SwiftUI

/// A slightly crooked rectangle, like a card cut out by hand.
struct WobblyRect: Shape {
    var variant = 0

    func path(in r: CGRect) -> Path {
        let o: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (3, 5, 3, 1, 5, 3, 2, 1),
            (2, 2, 2, 4, 5, 2, 3, 4),
            (3, 3, 3, 2, 2, 1, 2, 3),
            (2, 3, 2, 2, 4, 3, 3, 1),
        ]
        let v = o[abs(variant) % o.count]
        var p = Path()
        p.move(to: CGPoint(x: r.minX + v.0, y: r.minY + v.1))
        p.addLine(to: CGPoint(x: r.maxX - v.2, y: r.minY + v.3))
        p.addLine(to: CGPoint(x: r.maxX - v.4, y: r.maxY - v.5))
        p.addLine(to: CGPoint(x: r.minX + v.6, y: r.maxY - v.7))
        p.closeSubpath()
        return p
    }
}

/// The torn-paper edge of the main buttons.
struct TornShape: Shape {
    func path(in r: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [
            (0.015, 0.12), (0, 0.32), (0.012, 0.52), (0, 0.74), (0.018, 0.94),
            (0.984, 0.90), (1, 0.70), (0.986, 0.50), (1, 0.28), (0.982, 0.08),
        ]
        var p = Path()
        for (i, pt) in pts.enumerated() {
            let c = CGPoint(x: r.minX + pt.0 * r.width, y: r.minY + pt.1 * r.height)
            i == 0 ? p.move(to: c) : p.addLine(to: c)
        }
        p.closeSubpath()
        return p
    }
}

/// The organic shape on the right side of a card that holds the pattern.
struct SideBlob: Shape {
    /// Where the blob starts, as a share of the width.
    var start: CGFloat = 0.72
    var variant = 0

    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let x = r.minX + w * start
        let j: [CGFloat] = variant % 2 == 0 ? [-16, 10, -10, -4, -12] : [14, -8, 8, 16, 4]
        var p = Path()
        p.move(to: CGPoint(x: x, y: r.minY))
        p.addCurve(to: CGPoint(x: x - 10, y: r.minY + h * 0.61),
                   control1: CGPoint(x: x + j[0], y: r.minY + h * 0.2),
                   control2: CGPoint(x: x + j[1], y: r.minY + h * 0.41))
        p.addCurve(to: CGPoint(x: x - 12, y: r.maxY),
                   control1: CGPoint(x: x + j[2], y: r.minY + h * 0.73),
                   control2: CGPoint(x: x + j[3] + j[4], y: r.minY + h * 0.88))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

enum PatternStyle: Int, CaseIterable {
    case waves, hatch, dots, stripes

    var base: Color {
        switch self {
        case .waves: Color(hex: 0xE0EFEC)
        case .hatch: Color(hex: 0xFADCC8)
        case .dots: Color(hex: 0xFBF0C9)
        case .stripes: Color(hex: 0xECE5FB)
        }
    }

    var fill: Color {
        switch self {
        case .waves: Color(hex: 0x7FC8C1)
        case .hatch: Color(hex: 0xEE8A52)
        case .dots: Color(hex: 0xF6CF47)
        case .stripes: Color(hex: 0xB9A3EC)
        }
    }

    /// Selected-state tint used by option tiles and chips.
    var soft: Color {
        switch self {
        case .waves: Palette.teal
        case .hatch: Palette.peach
        case .dots: Palette.yellow
        case .stripes: Palette.lilac
        }
    }

    static func of(_ i: Int) -> PatternStyle { allCases[abs(i) % allCases.count] }
}

/// Hand-drawn texture for the blob area: blue waves, red cross-hatch, blue dots or pink bands.
struct PatternFill: View {
    let style: PatternStyle

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(style.fill))
            switch style {
            case .waves:
                let stroke = StrokeStyle(lineWidth: 5, lineCap: .round)
                var y: CGFloat = 16
                while y < size.height + 10 {
                    var p = Path()
                    var x: CGFloat = -10
                    p.move(to: CGPoint(x: x, y: y))
                    while x < size.width + 20 {
                        p.addQuadCurve(to: CGPoint(x: x + 18, y: y), control: CGPoint(x: x + 9, y: y - 9))
                        x += 18
                    }
                    ctx.stroke(p, with: .color(Color(hex: 0x3A6FD0)), style: stroke)
                    y += 28
                }
            case .hatch:
                var p = Path()
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    p.move(to: CGPoint(x: x, y: size.height))
                    p.addLine(to: CGPoint(x: x + size.height * 0.42, y: 0))
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + size.height * 0.42, y: size.height))
                    x += 32
                }
                ctx.stroke(p, with: .color(Color(hex: 0xDD5034)), lineWidth: 3)
            case .dots:
                var rng = SplitMix64(seed: 7)
                let count = Int(size.width * size.height / 520)
                for _ in 0..<max(count, 6) {
                    let x = CGFloat(rng.next() % 1000) / 1000 * size.width
                    let y = CGFloat(rng.next() % 1000) / 1000 * size.height
                    let r = 4 + CGFloat(rng.next() % 5)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0x6F88DB)))
                }
                var curve = Path()
                curve.move(to: CGPoint(x: -20, y: size.height * 0.95))
                curve.addCurve(to: CGPoint(x: size.width + 10, y: size.height * 0.2),
                               control1: CGPoint(x: size.width * 0.35, y: size.height * 0.6),
                               control2: CGPoint(x: size.width * 0.6, y: size.height * 0.75))
                ctx.stroke(curve, with: .color(Palette.ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            case .stripes:
                var y: CGFloat = 14
                while y < size.height + 10 {
                    var p = Path()
                    p.move(to: CGPoint(x: -10, y: y))
                    p.addCurve(to: CGPoint(x: size.width + 10, y: y + 4),
                               control1: CGPoint(x: size.width * 0.3, y: y - 8),
                               control2: CGPoint(x: size.width * 0.6, y: y + 12))
                    ctx.stroke(p, with: .color(Color(hex: 0xE07A8A)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    y += 26
                }
            }
        }
    }
}

/// White highlight stroke near the top of a card, like a gloss mark.
struct Gloss: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + 1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY + 2), control: CGPoint(x: r.midX, y: r.minY - 4))
        return p
    }
}
