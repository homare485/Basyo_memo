import Foundation
import Observation
import RevenueCat

/// 「Pro かどうか」と、Pro の購入・復元をまとめて扱う。
///
/// 画面からは RevenueCat を直接触らず、必ずここを通します。
/// こうしておくと、課金の仕組みを変えることになっても、直すのはこのファイルだけで済みます。
@Observable
final class ProAccess {
    /// Pro の権利が有効か。
    private(set) var isPro = false

    /// 売り場に並んでいる Pro の商品。読み込むまでは nil。
    private(set) var proPackage: Package?

    private(set) var isLoadingProduct = false
    private(set) var productLoadFailed = false

    /// 画面に出す価格（例: ¥500）。App Store の設定から自動で取ってきます。
    var priceText: String? {
        proPackage?.localizedPriceString
    }

    enum PurchaseOutcome {
        /// 購入が完了し、Pro になった
        case purchased
        /// 利用者が途中でやめた
        case cancelled
        /// 保護者の承認待ちなどで、まだ完了していない
        case pending
    }

    enum ProAccessError: Error {
        case productUnavailable
    }

    // MARK: - Setup

    /// アプリの起動時に一度だけ呼ぶ。
    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: PurchaseConfig.apiKey)
    }

    /// 購入状態の変化を見張り続ける。
    ///
    /// 購入・復元・オファーコードの利用・別の端末での購入など、
    /// どこで状態が変わっても、ここに届いて isPro が更新されます。
    func observeCustomerInfo() async {
        guard Purchases.isConfigured else { return }
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    /// 最新の状態を取り直す。
    func refresh() async {
        guard Purchases.isConfigured,
              let info = try? await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent) else { return }
        apply(info)
    }

    // MARK: - Product

    /// Pro の商品（価格など）を読み込む。
    func loadProduct() async {
        guard Purchases.isConfigured, proPackage == nil, !isLoadingProduct else { return }
        isLoadingProduct = true
        productLoadFailed = false
        defer { isLoadingProduct = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            // 買い切りの商品は「lifetime」として登録します。見つからなければ、売り場の最初の商品を使う。
            let current = offerings.current
            proPackage = current?.lifetime ?? current?.availablePackages.first
            productLoadFailed = proPackage == nil
        } catch {
            productLoadFailed = true
        }
    }

    // MARK: - Purchase

    func purchase() async throws -> PurchaseOutcome {
        guard let package = proPackage else { throw ProAccessError.productUnavailable }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(result.customerInfo)
            if result.userCancelled { return .cancelled }
            return isPro ? .purchased : .pending
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            return .cancelled
        } catch let error as ErrorCode where error == .paymentPendingError {
            return .pending
        }
    }

    /// 以前に買った Pro を取り戻す（機種変更・再インストールのとき）。戻り値は、復元後に Pro かどうか。
    func restore() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
        return isPro
    }

    // MARK: - Private

    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[PurchaseConfig.entitlementID]?.isActive == true
    }
}
