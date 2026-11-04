import SwiftUI

struct ProgressScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .bottom) {
                        ScreenTitle(text: "Прогресс")
                        Spacer()
                    }
                    statesBox
                    dueBox
                    regularity.padding(.top, 12)
                    accuracy
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .screenBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var statesBox: some View {
        let ids = model.library.items.map(\.id)
        let counts = model.counts(for: ids)
        let started = ids.count - (counts[.new] ?? 0)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(started) из \(ids.count) начаты").font(WPFont.nunito(16, .heavy))
                Spacer()
                Text("все уровни").font(WPFont.nunito(13)).foregroundStyle(Palette.inkSoft)
            }
            StateBar(counts: counts, total: ids.count, height: 16)
            stateRow(.mastered, counts, "Стабильность памяти не меньше 21 дня и минимум два верных ответа в разные дни. Изредка проверяем: это не «навсегда».")
            stateRow(.reviewing, counts, "Уже вспомнили верно, ждут следующей проверки.")
            stateRow(.learning, counts, "Познакомились, но ещё не закрепили, или ошиблись на последней проверке.")
            stateRow(.new, counts, nil)
        }
        .foregroundStyle(Palette.ink)
        .padding(16)
        .background(Color(hex: 0xE6DEF6), in: Radii.shape(0))
        .fillOutline(Radii.shape(0))
    }

    private func stateRow(_ s: LearningState, _ counts: [LearningState: Int], _ note: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(s == .new ? Color(hex: 0xFFFBF1) : Palette.stateColor(s))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.ink, lineWidth: 2))
                .frame(width: 12, height: 12)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(s.title).font(WPFont.nunito(15, .heavy))
                if let note { Text(note).font(WPFont.nunito(13)).foregroundStyle(Palette.inkSoft) }
            }
            Spacer()
            Text("\(counts[s] ?? 0)").font(WPFont.rubik(16, false)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var dueBox: some View {
        let due = model.dueIds().count
        return HStack(spacing: 14) {
            Text("\(due)").font(WPFont.rubik(30))
            Text(due == 0 ? "выражений ждут повторения сегодня" : "\(Plural.form(due, "выражение ждёт", "выражения ждут", "выражений ждут")) повторения сегодня")
                .font(WPFont.nunito(14, .semibold))
            Spacer()
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Palette.yellow, in: Radii.shape(2))
        .fillOutline(Radii.shape(2))
        .accessibilityElement(children: .combine)
    }

    private var regularity: some View {
        let today = model.today
        let studied = model.studiedDays
        // Monday-based weeks; today is somewhere in the last row.
        let weekday = (Calendar(identifier: .iso8601).component(.weekday, from: StudyDay.date(of: today)) + 5) % 7
        let start = today - weekday - 21
        let days = (0..<28).map { start + $0 }
        let past = days.filter { $0 <= today }
        let done = past.filter { studied.contains($0) }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Регулярность").font(WPFont.rubik(19, false)).foregroundStyle(Palette.text)
                Spacer()
                Text("4 недели").font(WPFont.nunito(13)).foregroundStyle(Palette.muted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    DayCell(index: i, studied: studied.contains(d), future: d > today, isToday: d == today)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("За 4 недели занятия в \(done) из \(past.count) дней")
            HStack(spacing: 6) {
                ForEach(["пн", "вт", "ср", "чт", "пт", "сб", "вс"], id: \.self) { d in
                    Text(d).font(WPFont.nunito(12, .bold)).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var accuracy: some View {
        HStack(spacing: 14) {
            if let a = model.firstAttemptAccuracy {
                Text("\(Int((a * 100).rounded()))%").font(WPFont.rubik(30))
                Text("повторений вспомнили с первой попытки за 30 дней").font(WPFont.nunito(14, .semibold))
            } else {
                Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 24, weight: .semibold))
                Text("Здесь появится доля повторений, которые вы вспомнили с первой попытки, когда наберётся история.")
                    .font(WPFont.nunito(14, .semibold))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(scheme == .dark ? Palette.text : Palette.ink)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(scheme == .dark ? Palette.paper : Palette.teal, in: Radii.shape(1))
        .boxOutline(Radii.shape(1))
        .accessibilityElement(children: .combine)
    }
}

/// One day in the «Регулярность» grid. In dark mode filled days have no border and only today gets a bright outline.
struct DayCell: View {
    @Environment(\.colorScheme) private var scheme
    let index: Int
    let studied: Bool
    let future: Bool
    let isToday: Bool

    var body: some View {
        let dark = scheme == .dark
        let shape = Radii.shape(index)
        shape
            .fill(future ? Color.clear : (studied ? Palette.blue : (dark ? Palette.paper : Color(hex: 0xFFFBF1))))
            .overlay {
                if future {
                    shape.stroke(dark ? Color(hex: 0x3A332D) : Palette.divider, style: StrokeStyle(lineWidth: dark ? 1.5 : 2, dash: [4, 3]))
                } else if dark {
                    shape.stroke(studied ? Palette.blue : Palette.outline, lineWidth: 1.5)
                } else {
                    shape.stroke(Palette.ink, lineWidth: 2)
                }
            }
            .overlay {
                if isToday && dark { shape.stroke(Color(hex: 0xF1E8D6), lineWidth: 2) }
            }
            .frame(height: 26)
    }
}
