import Foundation

/// 課金まわりの設定値。
enum PurchaseConfig {
    /// RevenueCat の公開用 API キー。
    ///
    /// - Debug（Xcode から実行）: `test_` で始まる Test Store のキー。App Store を通さずに購入を試せます
    /// - Release（TestFlight・App Store）: `appl_` で始まる App Store のキー
    ///
    /// どちらも「公開用」のキーなので、アプリに入れて問題ありません。
    /// RevenueCat の「秘密のキー（Secret API key）」は、絶対にここに書かないでください。
    #if DEBUG
    static let apiKey = "test_LrkAptHRCPliPcYVGsbEDNRGzCk"
    #else
    static let apiKey = "appl_NAqwtcOzvfGSeNZtfuDMLQKeIoY"
    #endif

    /// RevenueCat の権利（Entitlement）の ID。これが有効なら Pro。
    /// RevenueCat のダッシュボードにある Identifier と完全に一致させること。
    static let entitlementID = "basyo_memo_pro"

    /// 無料で作れる場所の数。
    static let freePlaceLimit = 5

    /// API キーがまだ仮の値のままか。
    static var hasPlaceholderKey: Bool {
        apiKey.contains("REPLACE_WITH")
    }
}
