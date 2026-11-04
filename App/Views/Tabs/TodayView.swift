import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    let openCatalog: () -> Void
    @State private var showWhy = false

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
                    ScreenTitle(text: plan.isEmpty ? "На сегодня всё" : "\(plan.total) \(Plural.cards(plan.total)) на сегодня")
                }

                if let resume = model.session {
                    resumeCard(resume)
                }

                if plan.isEmpty {
                    doneCard(plan)
                } else {
                    planCard(plan)
                    Button { showWhy.toggle() } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle").font(.system(size: 16, weight: .semibold)).padding(.top, 1)
                            Text("\(plan.newReason) Около \(model.estimateMinutes(reviews: plan.reviews.count, news: plan.news.count)) \(Plural.minutes(model.estimateMinutes(reviews: plan.reviews.count, news: plan.news.count))).")
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
                planRow(plan.reviews.count, plan.reviews.count == 1 ? "повторение" : Plural.reviews(plan.reviews.count),
                        plan.reviews.isEmpty ? "сегодня сроков нет" : "подошёл срок, идут первыми")
                Rectangle().fill(.clear).frame(height: 2)
                    .overlay(DashedDivider.Line().stroke(Palette.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                planRow(plan.news.count, plan.news.count == 1 ? "новое выражение" : "новых \(Plural.form(plan.news.count, "выражение", "выражения", "выражений"))",
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

    private func planRow(_ n: Int, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Text("\(n)").font(WPFont.rubik(44)).frame(minWidth: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(WPFont.nunito(17, .heavy))
                Text(subtitle).font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func doneCard(_ plan: DailyPlan) -> some View {
        PatternCard(style: .dots, variant: 1, blobStart: 0.72) {
            VStack(alignment: .leading, spacing: 10) {
                Text("План выполнен").font(WPFont.nunito(17, .heavy))
                Text(plan.levelFinished
                     ? "Новые выражения уровня \(model.prefs.level.rawValue) закончились."
                     : "Повторения появятся, когда подойдёт их срок. Новые можно взять в любой момент.")
                    .font(WPFont.nunito(14)).foregroundStyle(Palette.inkSoft)
                if plan.levelFinished, let next = model.prefs.level.next {
                    Button("Перейти на \(next.rawValue)") { model.updatePrefs { $0.level = next } }
                        .font(WPFont.nunito(15, .heavy)).underline().foregroundStyle(Palette.ink)
                        .frame(minHeight: 44)
                } else if !plan.levelFinished {
                    Button("Ещё 5 новых") { model.startExtraNew() }
                        .font(WPFont.nunito(15, .heavy)).underline().foregroundStyle(Palette.ink)
                        .frame(minHeight: 44)
                    Text("Лишние новые сегодня — это повторения через несколько дней.")
                        .font(WPFont.nunito(13)).foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(22)
            .frame(width: 240, alignment: .leading)
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
            .overlay(Radii.shape(1).stroke(Palette.outline, lineWidth: 2.5))
        }
        .buttonStyle(PressStyle())
    }

    private var expressionOfDay: some View {
        let item = model.expressionOfTheDay
        return PatternCard(style: .hatch, variant: 2, blobStart: 0.77) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Выражение дня").font(WPFont.hand(19)).foregroundStyle(Color(hex: 0x5A3A26))
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
