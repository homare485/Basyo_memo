import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        // 画面遷移の土台。Place Home → Spatial View →（次回）Space Detail と積み重なっていきます。
        NavigationStack {
            PlaceHomeView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(.preview)
        .environment(ProAccess())
}

// Try to PR for Homare
