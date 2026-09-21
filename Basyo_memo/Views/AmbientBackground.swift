import SwiftUI

/// 全画面共通の背景。
/// 上から下へ、ほとんど見えない程度に沈んでいくグラデーションで奥行きだけを出します。
struct AmbientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.primary.opacity(0), Color.primary.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
