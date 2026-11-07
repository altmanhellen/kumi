import Foundation
import StoreKit

/// The one-time purchase that opens every expression. The first `freeNewLimit` new expressions are free;
/// reviews of anything already started stay free forever.
@MainActor
@Observable
final class Store {
    static let fullAccessId = "com.elenaaltman.kumi.full"

    private(set) var product: Product?
    private(set) var busy = false
    var message: String?
    private weak var model: AppModel?
    private var updates: Task<Void, Never>?

    func start(model: AppModel) {
        self.model = model
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if a.contains("-wpUnlocked") { model.isUnlocked = true; return }
        if a.contains("-wpPaywall") { model.showPaywall = true }
        if a.contains("-wpLocked") { return }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result { await t.finish() }
                await self?.refresh()
            }
        }
        Task {
            await refresh()
            await loadProduct()
        }
    }

    /// Asks the App Store for the product; repeated on a purchase attempt if the first try failed (no internet at launch).
    func loadProduct() async {
        if product == nil { product = try? await Product.products(for: [Self.fullAccessId]).first }
    }

    /// Reads the purchases Apple has on record for this Apple Account.
    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.fullAccessId, t.revocationDate == nil { owned = true }
        }
        model?.isUnlocked = owned
    }

    func buy() async {
        busy = true
        defer { busy = false }
        await loadProduct()
        guard let product else { message = "Не удалось связаться с App Store. Проверьте интернет и попробуйте ещё раз."; return }
        do {
            switch try await product.purchase() {
            case .success(let result):
                if case .verified(let t) = result { await t.finish() }
                await refresh()
            case .pending:
                message = "Покупка ждёт подтверждения. Доступ откроется, как только App Store её подтвердит."
            default: break
            }
        } catch {
            message = "Покупка не прошла: \(error.localizedDescription)"
        }
    }

    func restore() async {
        busy = true
        defer { busy = false }
        try? await AppStore.sync()
        await refresh()
        if model?.isUnlocked != true { message = "Покупок на этой учётной записи Apple не нашлось." }
    }

    /// Price as the App Store shows it in the user's country, or a fallback before it loads.
    var price: String { product?.displayPrice ?? "$7.99" }
}
