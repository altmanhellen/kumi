import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    let openCatalog: () -> Void
    var openTopic: (String) -> Void = { _ in }
    @State private var showWhy = false
    @State private var showAllNew = false

    private var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EE, d MMMM"
        return "Сегодня · " + f.string(from: Date())
    }

    var body: some View {
        let plan = model.plan
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: dateLine)
                    ScreenTitle(text: plan.isEmpty ? "Вы молодец!" : "\(plan.total) \(Plural.cards(plan.total)) на сегодня")
                }

                if let resume = model.session {
                    resumeCard(resume)
                }

                if plan.isEmpty {
                    doneCard(plan)
                    if let topic = model.continueTopic {
                        continueCard(topic)
                    }
                } else {
                    planCard(plan)
                    Button { showWhy.toggle() } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle").font(.system(size: 16, weight: .semibold)).padding(.top, 1)
                            Text("Рекомендуется не больше 10 новых фраз в день.")
                                .multilineTextAlignment(.leading)
                        }
                        .font(WPFont.nunito(14))
                        .foregroundStyle(Palette.muted)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)

                    PrimaryButton(title: model.session == nil ? "Начать занятие" : "Начать заново") {
                        if model.session != nil { model.closeSession() }
                        model.startToday()
                    }
                    .padding(.top, 4)
                }

                LinkButton(title: "или выбрать тему в Каталоге", action: openCatalog)
                    .frame(maxWidth: .infinity)

                expressionOfDay
                    .padding(.top, 8)

                if plan.isEmpty && !model.startedTodayIds.isEmpty {
                    newTodayCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .alert("Почему столько карточек", isPresented: $showWhy) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(whyText(plan))
        }
        .sheet(isPresented: Binding(get: { model.shouldOfferReminder }, set: { model.shouldOfferReminder = $0 })) {
            ReminderOffer()
                .presentationDetents([.height(360)])
        }
    }

    private func whyText(_ plan: DailyPlan) -> String {
        var parts: [String] = []
        parts.append("Сначала идут выражения, у которых подошёл срок повторения: сегодня их \(plan.dueTotal), в занятие берём не больше \(model.prefs.reviewLimit).")
        parts.append(plan.newReason)
        return parts.joined(separator: "\n\n")
    }

    private func planCard(_ plan: DailyPlan) -> some View {
        PatternCard(style: .waves, blobStart: 0.74) {
            VStack(alignment: .leading, spacing: 18) {
                planRow(plan.reviews.count, widest: max(plan.reviews.count, plan.news.count), plan.reviews.count == 1 ? "повторение" : Plural.reviews(plan.reviews.count),
                        plan.reviews.isEmpty ? "сегодня сроков нет" : "подошёл срок, идут первыми")
                Rectangle().fill(.clear).frame(height: 2)
                    .overlay(DashedDivider.Line().stroke(Palette.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                planRow(plan.news.count, widest: max(plan.reviews.count, plan.news.count), plan.news.count == 1 ? "новое выражение" : "новых \(Plural.form(plan.news.count, "выражение", "выражения", "выражений"))",
                        newSubtitle)
            }
            .padding(22)
            .frame(width: 250, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var newSubtitle: String {
        let topics = model.prefs.topics.prefix(2).joined(separator: ", ")
        return topics.isEmpty ? "уровень \(model.prefs.level.rawValue)" : "\(topics) · \(model.prefs.level.rawValue)"
    }

    /// Both rows reserve room for the wider number, so the text starts at the same place.
    private func planRow(_ n: Int, widest: Int, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .leading) {
                Text(String(repeating: "8", count: String(widest).count)).hidden()
                Text("\(n)")
            }
            .font(WPFont.rubik(44))
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(WPFont.nunito(17, .heavy))
                Text(subtitle).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func phrases(_ n: Int) -> String { "\(n) \(Plural.form(n, "фразу", "фразы", "фраз"))" }

    /// Today's progress: only the rows above zero. Hidden when nothing happened today.
    @ViewBuilder
    private func doneCard(_ plan: DailyPlan) -> some View {
        let t = model.todayStats
        let rows: [(String, String)] = [
            ("Освоили", t.mastered > 0 ? phrases(t.mastered) : ""),
            ("Повторили", t.reviews > 0 ? phrases(t.reviews) : ""),
            ("Начали учить", t.news > 0 ? phrases(t.news) : ""),
            ("Время", t.minutes > 0 ? "\(t.minutes) мин" : ""),
        ].filter { !$0.1.isEmpty }
        if !rows.isEmpty || plan.levelFinished {
            VStack(alignment: .leading, spacing: 0) {
                Text("Сегодня").font(WPFont.rubik(19)).padding(.bottom, 6)
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    if i > 0 {
                        DashedDivider.Line().stroke(Palette.ink.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(height: 2)
                    }
                    HStack {
                        Text(row.0).font(WPFont.nunito(15, .bold))
                        Spacer()
                        Text(row.1).font(WPFont.rubik(18))
                    }
                    .frame(minHeight: 40)
                    .accessibilityElement(children: .combine)
                }
                if plan.levelFinished, let next = model.prefs.level.next {
                    Button("Новые уровня \(model.prefs.level.rawValue) закончились · перейти на \(next.rawValue)") {
                        model.updatePrefs { $0.level = next }
                    }
                    .font(WPFont.nunito(14, .heavy)).underline().foregroundStyle(Palette.ink)
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            .padding(.leading, 20).padding(.trailing, 92).padding(.vertical, 16)
            .wrapInPatternCard(.dots, variant: 1)
        }
    }

    private func continueCard(_ topic: String) -> some View {
        let level = model.prefs.level
        let ids = model.library.items.filter { $0.topics.contains(topic) && $0.level == level }.map(\.id)
        let counts = model.counts(for: ids)
        let fresh = counts[.new] ?? 0
        return Button { openTopic(topic) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(WPFont.labelText("Продолжить тему")).font(WPFont.label(23)).foregroundStyle(Palette.inkSoft)
                Text("\(topic) · \(level.rawValue)").font(WPFont.rubik(22)).multilineTextAlignment(.leading)
                Text("\(fresh) \(Plural.form(fresh, "новое", "новых", "новых")) →").font(WPFont.nunito(15, .heavy))
                StateBar(counts: counts, total: ids.count).padding(.top, 4)
            }
            .padding(.leading, 20).padding(.trailing, 92).padding(.vertical, 16)
            .wrapInPatternCard(.waves, variant: 0)
        }
        .buttonStyle(PressStyle())
    }

    private var newTodayCard: some View {
        let ids = model.startedTodayIds.compactMap { model.library[$0] }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Новые сегодня").font(WPFont.rubik(19, false))
                Spacer()
                if ids.count > 3 {
                    Button("все \(ids.count)") { showAllNew = true }
                        .font(WPFont.nunito(15, .heavy)).underline().foregroundStyle(Palette.ink)
                        .frame(minHeight: 44)
                }
            }
            ForEach(ids.prefix(3)) { item in
                // The speaker lines up with the bold English phrase, not the middle of the row.
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Button { model.speakEnglish(item.phrase) } label: {
                        Image(systemName: "speaker.wave.2").font(.system(size: 16, weight: .semibold)).frame(width: 40, height: 40)
                    }
                    .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 6 }
                    .accessibilityLabel("Послушать: \(item.phrase)")
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.phrase).font(WPFont.rubik(17, false))
                        Text(item.translationRu).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.leading, 20).padding(.trailing, 92).padding(.vertical, 16)
        .wrapInPatternCard(.stripes, variant: 2)
        .sheet(isPresented: $showAllNew) {
            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(ids) { item in ExpressionRow(item: item) { } }
                    }
                    .padding(20)
                }
                .screenBackground()
                .navigationTitle("Новые сегодня")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func resumeCard(_ s: SessionState) -> some View {
        Button { model.showingSession = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill").font(.system(size: 16, weight: .bold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Продолжить занятие").font(WPFont.nunito(16, .heavy))
                    Text("шаг \(s.index + 1) из \(s.steps.count)").font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Palette.ink)
            .padding(14)
            .background(Palette.yellow, in: Radii.shape(1))
            .fillOutline(Radii.shape(1))
        }
        .buttonStyle(PressStyle())
    }

    private var expressionOfDay: some View {
        let item = model.expressionOfTheDay
        return PatternCard(style: .hatch, variant: 2, blobStart: 0.77) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(WPFont.labelText("Выражение дня")).font(WPFont.label(21)).foregroundStyle(Color(hex: 0x5A3A26))
                    Text(item.phrase).font(WPFont.rubik(21, false)).environment(\.locale, Locale(identifier: "en"))
                    if model.prefs.showTranslation {
                        Text(item.translationRu).font(WPFont.nunito(14)).foregroundStyle(Color(hex: 0x4A3A2E))
                    } else {
                        Text(item.meaningEn).font(WPFont.nunito(14)).foregroundStyle(Color(hex: 0x4A3A2E))
                    }
                }
                Spacer(minLength: 8)
                ListenButton(label: "Послушать: \(item.phrase)", size: 48, fill: Palette.cream) { model.speakEnglish(item.phrase) }
            }
            .padding(.vertical, 12)
            .padding(.leading, 20)
            .padding(.trailing, 16)
        }
    }
}

struct ReminderOffer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Два занятия позади")
            ScreenTitle(text: "Напоминать о занятии?", size: 26)
            Text("Раз в день, в 19:00. Время можно поменять в настройках.")
                .font(WPFont.nunito(16)).foregroundStyle(Palette.muted)
            Spacer()
            PrimaryButton(title: "Напоминать") {
                Task {
                    let ok = await Reminders.requestAndSchedule(hour: model.prefs.reminderHour, minute: model.prefs.reminderMinute)
                    model.updatePrefs { $0.reminderEnabled = ok }
                    dismiss()
                }
            }
            LinkButton(title: "Не сейчас") { dismiss() }.frame(maxWidth: .infinity)
        }
        .padding(24)
        .screenBackground()
    }
}

private extension View {
    /// Today cards use the same illustrated card as the Catalog groups.
    func wrapInPatternCard(_ style: PatternStyle, variant: Int) -> some View {
        PatternCard(style: style, variant: variant, blobStart: 0.78) { self }
    }
}
