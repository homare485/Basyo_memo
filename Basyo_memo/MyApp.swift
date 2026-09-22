import SwiftUI
import SwiftData

@main
struct BasyoMemoApp: App {
    /// SwiftData のデータベース本体。アプリ全体で1つだけ作ります。
    let container: ModelContainer

    /// Pro かどうかと、その購入・復元。アプリ全体で1つだけ作り、全画面に配ります。
    @State private var pro = ProAccess()

    init() {
        do {
            container = try ModelContainer(for: Place.self, Space.self, TaskItem.self)
        } catch {
            fatalError("データベースを開けませんでした: \(error)")
        }
        SampleData.insertIfNeeded(into: container.mainContext)
        ProAccess.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pro)
                // アプリが開いている間、購入状態の変化を見張り続ける。
                .task { await pro.observeCustomerInfo() }
        }
        // これで、下の全ての View から @Query や modelContext が使えるようになります。
        .modelContainer(container)
    }
}
