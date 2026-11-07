import SwiftUI

struct ProgressScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    @State private var path = NavigationPath()
    @State private var filter: Level?
    @State private var filterChosen = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .bottom) {
                        ScreenTitle(text: "Прогресс")
                        Spacer()
                    }
                    statesBox
                    regularity.padding(.top, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            #if DEBUG
            .onAppear { _ = proxy }
            #endif
            }
            .screenBackground()
            .statusBarBackdrop()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    /// nil means all levels. Starts at the user's level; kept while the app stays open.
    private var currentFilter: Level? { filterChosen ? filter : model.prefs.level }

    private var levelFilter: some View {
        HStack(spacing: 0) {
            ForEach(Array(([nil] + Level.allCases.map { Optional($0) }).enumerated()), id: \.offset) { i, l in
                let on = currentFilter == l
                Button { filter = l; filterChosen = true } label: {
                    Text(l?.rawValue ?? "Все")
                        .font(WPFont.rubik(15, false))
                        .foregroundStyle(on ? Color(hex: 0xF4EDDC) : Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? Palette.ink : .clear)
                        .overlay(alignment: .leading) {
                            if i > 0 { Rectangle().fill(Palette.ink).frame(width: 2) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l.map { "Уровень \($0.rawValue)" } ?? "Все уровни")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .background(Color(hex: 0xFFFBF1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.ink, lineWidth: 2.5))
    }

    private var statesBox: some View {
        let ids = model.library.items.filter { currentFilter == nil || $0.level == currentFilter }.map(\.id)
        let counts = model.counts(for: ids)
        let started = ids.count - (counts[.new] ?? 0)
        return VStack(alignment: .leading, spacing: 10) {
            levelFilter.padding(.bottom, 4)
            Text("\(started) из \(ids.count) начаты").font(WPFont.nunito(16, .heavy))
            StateBar(counts: counts, total: ids.count, height: 16)
            stateRow(.mastered, counts)
            stateRow(.reviewing, counts)
            stateRow(.learning, counts)
            stateRow(.new, counts)
        }
        .foregroundStyle(Palette.ink)
        .padding(16)
        .background(Color(hex: 0xE6DEF6), in: Radii.shape(0))
        .fillOutline(Radii.shape(0))
    }

    private func stateRow(_ s: LearningState, _ counts: [LearningState: Int]) -> some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(s == .new ? Color(hex: 0xFFFBF1) : Palette.stateColor(s))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.ink, lineWidth: 2))
                .frame(width: 12, height: 12)
            Text(s.progressTitle).font(WPFont.nunito(15, .heavy))
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Точность памяти").font(WPFont.rubik(17, false))
            HStack(spacing: 14) {
                if let a = model.firstAttemptAccuracy {
                    Text("\(Int((a * 100).rounded()))%").font(WPFont.rubik(30))
                    Text("фраз вы вспомнили сразу, без подсказок и ошибок · за 30 дней").font(WPFont.nunito(14, .semibold))
                } else {
                    Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 24, weight: .semibold))
                    Text("Покажет, какую часть фраз вы вспоминаете сразу, без подсказок и ошибок. Появится после первых \(AppModel.accuracyMinimum) повторений.")
                        .font(WPFont.nunito(14, .semibold))
                }
                Spacer(minLength: 0)
            }
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
                    shape.stroke(dark ? Color(hex: 0x6B6157) : Palette.divider, style: StrokeStyle(lineWidth: dark ? 1.5 : 2, dash: [4, 3]))
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
