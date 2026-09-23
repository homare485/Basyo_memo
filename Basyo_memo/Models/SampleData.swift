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

            for (spaceIndex, spaceSeed) in seed.spaces.enumerated() {
                let space = Space(name: spaceSeed.name, symbolName: spaceSeed.symbolName,
                                  size: spaceSeed.size, sortIndex: spaceIndex)
                // 先に insert してから関係を結ぶのが SwiftData の安全な順番です。
                context.insert(space)
                space.place = place

                for title in spaceSeed.tasks {
                    // サンプルだと一目で分かるようにする。完了させればそのまま消せます。
                    // 端末の言語に合わせた文言で入ります（英語の端末なら英語）。
                    let localized = String(localized: String.LocalizationValue(title))
                    let task = TaskItem(title: String(localized: "\(localized)（サンプル）"), createdAt: createdAt)
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
        let size: RoomSize
        var tasks: [String] = []
    }

    private static let seeds: [PlaceSeed] = [
        // 間取り（横2列のマス目に、上から順に詰めて並べる）
        //
        //  ┌─────────┬─────────┐
        //  │         │BATH  (小)│
        //  │ BEDROOM ├─────────┤
        //  │   (中)  │TOILET(小)│
        //  ├─────────┼─────────┤
        //  │ LIVING  │ KITCHEN │
        //  │   (中)  │   (中)  │
        //  └─────────┴─────────┘
        PlaceSeed(name: "HOME", symbolName: "house", spaces: [
            SpaceSeed(name: "Bedroom", symbolName: "bed.double", size: .medium,
                      tasks: ["シーツを洗う"]),
            SpaceSeed(name: "Bathroom", symbolName: "bathtub", size: .small,
                      tasks: ["シャンプーを詰め替える"]),
            SpaceSeed(name: "Toilet", symbolName: "toilet", size: .small),
            SpaceSeed(name: "Living", symbolName: "sofa", size: .medium,
                      tasks: ["電池を交換"]),
            SpaceSeed(name: "Kitchen", symbolName: "frying.pan", size: .medium,
                      tasks: ["ゴミ袋を補充", "洗剤を確認", "シンクを掃除"])
        ]),
        PlaceSeed(name: "UNIVERSITY", symbolName: "graduationcap", spaces: [
            SpaceSeed(name: "Classroom", symbolName: "person.3", size: .large,
                      tasks: ["レポートを提出"]),
            SpaceSeed(name: "Library", symbolName: "books.vertical", size: .medium,
                      tasks: ["借りた本を返す"])
        ]),
        PlaceSeed(name: "WORK", symbolName: "briefcase", spaces: [
            SpaceSeed(name: "Desk", symbolName: "laptopcomputer", size: .large),
            SpaceSeed(name: "Meeting Room", symbolName: "person.2", size: .medium)
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
