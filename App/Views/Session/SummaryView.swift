import SwiftUI

struct SummaryView: View {
    @Environment(AppModel.self) private var model
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: summary.source == .onboarding ? "Первое занятие" : "Отлично!", size: 24)
                    ScreenTitle(text: "Занятие завершено")

                    HStack(spacing: 10) {
                        stat(summary.reviews, Plural.reviews(summary.reviews), Palette.yellow, 0)
                        stat(summary.newStarted, "новых начато", Palette.lilac, 1)
                        stat(summary.fixedMistakes, Plural.form(summary.fixedMistakes, "ошибка исправлена", "ошибки исправлены", "ошибок исправлено"), Palette.teal, 2)
                    }
                    .padding(.top, 22)

                    if summary.source == .onboarding {
                        Text("\(summary.newStarted) \(Plural.expressions(summary.newStarted)) начаты. Завтра проверим их и дадим новые.")
                            .font(WPFont.nunito(16)).foregroundStyle(Palette.secondary).padding(.top, 18)
                    }

                    if !summary.rows.isEmpty {
                        Text("График повторений").font(WPFont.rubik(19, false)).foregroundStyle(Palette.text).padding(.top, 26)
                        Text("Ошибки уже повторили в конце занятия. Дальше каждое выражение вернётся в свой срок.")
                            .font(WPFont.nunito(14)).foregroundStyle(Palette.muted).padding(.top, 4)
                        PaperBox(variant: 0) {
                            ForEach(Array(summary.rows.enumerated()), id: \.element.id) { i, r in
                                if i > 0 {
                                    DashedDivider.Line().stroke(Palette.divider, style: StrokeStyle(lineWidth: 2, dash: [6, 5])).frame(height: 2)
                                }
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(r.phrase).font(WPFont.rubik(17, false))
                                        Text(r.note).font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    Text(r.next).font(WPFont.nunito(14, .heavy))
                                }
                                .foregroundStyle(Palette.text)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .frame(minHeight: 60)
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.top, 12)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "calendar").font(.system(size: 22, weight: .semibold))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Следующее занятие").font(WPFont.nunito(16, .heavy))
                            Text("завтра: \(summary.tomorrowDue) \(Plural.reviews(summary.tomorrowDue)) + новые по лимиту")
                                .font(WPFont.nunito(14)).foregroundStyle(Color(hex: 0x4A3A2E))
                        }
                        Spacer()
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Palette.blush, in: Radii.shape(1))
                    .overlay(Radii.shape(1).stroke(Palette.outline, lineWidth: 2.5))
                    .padding(.top, 16)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.icloud").font(.system(size: 13))
                        Text("Результаты сохранены на этом iPhone").font(WPFont.nunito(13))
                    }
                    .foregroundStyle(Palette.muted)
                    .padding(.top, 14)
                }
                .padding(.top, 30)
                .padding(.bottom, 12)
            }
            PrimaryButton(title: "Готово") { model.dismissSummary() }
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
    }

    private func stat(_ n: Int, _ label: String, _ fill: Color, _ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(n)").font(WPFont.rubik(30))
            Text(label).font(WPFont.nunito(14, .bold)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Palette.ink)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(fill, in: Radii.shape(i))
        .overlay(Radii.shape(i).stroke(Palette.outline, lineWidth: 2.5))
        .accessibilityElement(children: .combine)
    }
}
