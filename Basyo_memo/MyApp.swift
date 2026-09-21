import SwiftUI
import SwiftData

@main
struct BasyoMemoApp: App {
    /// SwiftData のデータベース本体。アプリ全体で1つだけ作ります。
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Place.self, Space.self, TaskItem.self)
        } catch {
            fatalError("データベースを開けませんでした: \(error)")
        }
        SampleData.insertIfNeeded(into: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // これで、下の全ての View から @Query や modelContext が使えるようになります。
        .modelContainer(container)
    }
}
