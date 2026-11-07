import SwiftUI

/// Offer to open every expression with the one-time purchase.
struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .bold)).foregroundStyle(Palette.text)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Закрыть")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Полный доступ")
                    HighlightTitle(lead: "Все 326", mark: "выражений")
                    Text("Первые \(AppModel.freeNewLimit) выражений бесплатны. Одна покупка открывает остальные навсегда, без подписки.")
                        .font(WPFont.nunito(17)).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                    PaperBox(variant: 1) {
                        VStack(alignment: .leading, spacing: 12) {
                            point("Все уровни от A2 до C1 и все темы")
                            point("Повторения по расписанию, чтобы фразы не забывались")
                            point("Один раз платите, пользуетесь всегда")
                            point("Без рекламы и подписки, занятия без интернета")
                        }
                        .padding(16)
                    }
                    .padding(.top, 22)
                    Text("Повторять уже начатые выражения можно и без покупки.")
                        .font(WPFont.nunito(14)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12).padding(.horizontal, 4)
                }
                .padding(.top, 4)
            }
            .scrollBounceBehavior(.basedOnSize)
            if model.isUnlocked {
                Text("Готово! Все выражения открыты.").font(WPFont.nunito(17, .heavy)).foregroundStyle(Palette.text)
                    .frame(maxWidth: .infinity).padding(.bottom, 10)
                PrimaryButton(title: "Учиться дальше") { dismiss() }
            } else {
                PrimaryButton(title: store.busy ? "Подождите…" : "Открыть всё · \(store.price)", enabled: !store.busy) {
                    Task { await store.buy() }
                }
                LinkButton(title: "Восстановить покупку") { Task { await store.restore() } }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
        .screenBackground()
        .task { await store.loadProduct() }
        .alert(store.message ?? "", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("Ок", role: .cancel) {}
        }
    }

    private func point(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark").font(.system(size: 14, weight: .black)).foregroundStyle(Palette.green)
            Text(text).font(WPFont.nunito(16, .semibold)).foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Today-screen card shown once the free expressions are used up.
struct UnlockCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { model.showPaywall = true } label: {
            PatternCard(style: .stripes, variant: 1, blobStart: 0.78, clearBlob: true) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(WPFont.labelText("Бесплатные выражения закончились")).font(WPFont.label(22)).foregroundStyle(Palette.inkSoft)
                    Text("Откройте все 326").font(WPFont.rubik(22))
                    Text("Разовая покупка, без\u{00A0}подписки\u{00A0}→").font(WPFont.nunito(15, .heavy))
                }
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .padding(.leading, 20).padding(.vertical, 16)
            }
        }
        .buttonStyle(PressStyle())
    }
}
