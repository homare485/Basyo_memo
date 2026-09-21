import Foundation
import SwiftData

/// 初回起動時に入れておくデータ。
///
/// いまはまだ Place と Space を作る画面がないので、ここで用意しておきます。
enum SampleData {
    /// データベースが空のときだけ、サンプルを投入する。
    /// 2回目以降の起動では何もしないので、ユーザーが追加・完了したタスクは上書きされません。
    static func insertIfNeeded(into context: ModelContext) {
        let placeCount = (try? context.fetchCount(FetchDescriptor<Place>())) ?? 0
        guard placeCount == 0 else { return }

        // 並び順が毎回同じになるよう、作成日時を1秒ずつずらす。
        var createdAt = Date.now

        for (index, seed) in seeds.enumerated() {
            let place = Place(name: seed.name, symbolName: seed.symbolName, sortIndex: index)
            context.insert(place)

            for spaceSeed in seed.spaces {
                let space = Space(name: spaceSeed.name, symbolName: spaceSeed.symbolName, plan: spaceSeed.plan)
                // 先に insert してから関係を結ぶのが SwiftData の安全な順番です。
                context.insert(space)
                space.place = place

                for title in spaceSeed.tasks {
                    // サンプルだと一目で分かるようにする。完了させればそのまま消せます。
                    let task = TaskItem(title: "\(title)（サンプル）", createdAt: createdAt)
                    context.insert(task)
                    task.space = space
                    createdAt += 1
                }
            }
        }

        try? context.save()
    }

    // MARK: - Seeds

    private struct PlaceSeed {
        let name: String
        let symbolName: String
        let spaces: [SpaceSeed]
    }

    private struct SpaceSeed {
        let name: String
        let symbolName: String
        let plan: PlanRect
        var tasks: [String] = []
    }

    private static let seeds: [PlaceSeed] = [
        // 間取り（左 60% / 右 40%）
        //
        //  ┌──────────┬───────┐
        //  │ BEDROOM  │ BATH  │
        //  │          ├───────┤
        //  │          │TOILET │
        //  ├──────────┼───────┤
        //  │          │       │
        //  │  LIVING  │KITCHEN│
        //  │          │       │
        //  └──┘    └──┴───────┘  ← 下辺の隙間が玄関
        PlaceSeed(name: "HOME", symbolName: "house", spaces: [
            SpaceSeed(name: "Bedroom", symbolName: "bed.double",
                      plan: PlanRect(x: 0, y: 0, width: 0.6, height: 0.4),
                      tasks: ["シーツを洗う"]),
            SpaceSeed(name: "Living", symbolName: "sofa",
                      plan: PlanRect(x: 0, y: 0.4, width: 0.6, height: 0.6),
                      tasks: ["電池を交換"]),
            SpaceSeed(name: "Kitchen", symbolName: "frying.pan",
                      plan: PlanRect(x: 0.6, y: 0.4, width: 0.4, height: 0.6),
                      tasks: ["ゴミ袋を補充", "洗剤を確認", "シンクを掃除"]),
            SpaceSeed(name: "Bathroom", symbolName: "bathtub",
                      plan: PlanRect(x: 0.6, y: 0, width: 0.4, height: 0.24),
                      tasks: ["シャンプーを詰め替える"]),
            SpaceSeed(name: "Toilet", symbolName: "toilet",
                      plan: PlanRect(x: 0.6, y: 0.24, width: 0.4, height: 0.16))
        ]),
        // UNIVERSITY / WORK の間取りは仮です。
        PlaceSeed(name: "UNIVERSITY", symbolName: "graduationcap", spaces: [
            SpaceSeed(name: "Classroom", symbolName: "person.3",
                      plan: PlanRect(x: 0, y: 0, width: 1, height: 0.55),
                      tasks: ["レポートを提出"]),
            SpaceSeed(name: "Library", symbolName: "books.vertical",
                      plan: PlanRect(x: 0, y: 0.55, width: 1, height: 0.45),
                      tasks: ["借りた本を返す"])
        ]),
        PlaceSeed(name: "WORK", symbolName: "briefcase", spaces: [
            SpaceSeed(name: "Desk", symbolName: "laptopcomputer",
                      plan: PlanRect(x: 0, y: 0, width: 1, height: 0.6)),
            SpaceSeed(name: "Meeting Room", symbolName: "person.2",
                      plan: PlanRect(x: 0, y: 0.6, width: 1, height: 0.4))
        ])
    ]
}

// MARK: - Preview

extension ModelContainer {
    /// Xcode のプレビュー用。ディスクには保存せず、メモリ上にサンプル入りで作ります。
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Place.self, Space.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        SampleData.insertIfNeeded(into: container.mainContext)
        return container
    }
}
