import SwiftUI
import StoreKit
import UIKit

/// Pro の案内（課金画面）。
///
/// 無料で作れる場所（3つ）を使い切った状態で「新しい場所」を押したときに出ます。
/// 押し売りにならないよう、何ができるようになるかを短く伝えるだけにしています。
struct ProPaywallView: View {
    /// Pro になったときに呼ばれる。Place Home は、これを受けて場所の追加に進みます。
    let onUnlocked: () -> Void

    @Environment(ProAccess.self) private var pro
    @Environment(\.dismiss) private var dismiss

    /// 購入や復元の処理中か。二重に押されないようにする。
    @State private var isWorking = false

    /// ボタンの下に出す一言（キャンセルしたとき、エラーのときなど）。
    @State private var message: String?

    /// App Store のオファーコード入力画面を開いているか。
    @State private var isRedeemingCode = false

    /// onUnlocked を二度呼ばないための印。
    @State private var didUnlock = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("BASYO PRO")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")
            }

            Text("場所を、もっと。")
                .font(.system(size: 28, weight: .light))
                .padding(.top, 14)

            Text("無料では、場所を\(PurchaseConfig.freePlaceLimit)つまでつくれます。Pro にすると、実家やジム、カフェなど、よく行く場所をいくつでも足せます。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 14) {
                feature("plus.square.on.square", "場所を、いくつでも追加")
                feature("checkmark.seal", "一度の購入で、ずっと使える")
                feature("square.grid.2x2", "部屋とやることは、これまで通り無制限")
            }
            .padding(.top, 28)

            Spacer(minLength: 24)

            if let message = message ?? loadFailureMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            purchaseButton

            HStack {
                Button("購入を復元", action: restore)
                Spacer()
                Button("コードを使う") { isRedeemingCode = true }
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .disabled(isWorking)
            .padding(.top, 18)
            .padding(.horizontal, 4)
        }
        .padding(28)
        .animation(.easeOut(duration: 0.2), value: message)
        .presentationDetents([.height(560)])
        .presentationBackground(Color(uiColor: .systemBackground))
        .task { await pro.loadProduct() }
        // App Store のオファーコード入力画面（審査員や、コードを受け取った人向け）。
        .offerCodeRedemption(isPresented: $isRedeemingCode) { _ in
            Task { await pro.refresh() }
        }
        // 購入・復元・コードなど、どの方法でも Pro になった時点で閉じる。
        .onChange(of: pro.isPro) { _, isPro in
            if isPro { unlock() }
        }
        .sensoryFeedback(.success, trigger: didUnlock)
    }

    // MARK: - Parts

    private func feature(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 15))
        }
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            ZStack {
                if isWorking || (pro.isLoadingProduct && pro.proPackage == nil) {
                    ProgressView()
                        .tint(Color(uiColor: .systemBackground))
                } else {
                    Text(purchaseTitle)
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(Color.primary))
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }

    /// 価格を読み込めなかったときの一言。
    private var loadFailureMessage: String? {
        guard pro.productLoadFailed, !pro.isLoadingProduct else { return nil }
        return "価格を読み込めませんでした。通信状況を確かめて、もう一度お試しください。"
    }

    private var purchaseTitle: String {
        if let price = pro.priceText { return "\(price) で Pro にする" }
        return pro.productLoadFailed ? "もう一度読み込む" : "Pro にする"
    }

    // MARK: - Actions

    private func purchase() {
        // 価格を読み込めていなければ、まず読み込み直す。
        guard pro.proPackage != nil else {
            Task { await pro.loadProduct() }
            return
        }

        isWorking = true
        message = nil
        Task {
            defer { isWorking = false }
            do {
                switch try await pro.purchase() {
                case .purchased:
                    unlock()
                case .cancelled:
                    break
                case .pending:
                    message = "購入の承認を待っています。承認されると、自動で Pro になります。"
                }
            } catch {
                message = "購入できませんでした。通信状況を確かめて、もう一度お試しください。"
            }
        }
    }

    private func restore() {
        isWorking = true
        message = nil
        Task {
            defer { isWorking = false }
            do {
                if try await pro.restore() {
                    unlock()
                } else {
                    message = "復元できる購入が見つかりませんでした。"
                }
            } catch {
                message = "復元できませんでした。通信状況を確かめて、もう一度お試しください。"
            }
        }
    }

    private func unlock() {
        guard !didUnlock else { return }
        didUnlock = true
        onUnlocked()
        dismiss()
    }
}
