import Foundation
import SwiftData

/// Place の中にある「空間」。Kitchen / Library / Desk など。
@Model
final class Space {
    var id: UUID
    var name: String
    var symbolName: String

    /// 間取り図の上での位置と大きさ。
    var plan: PlanRect

    /// この空間が属する場所。
    var place: Place?

    /// この空間に置かれているタスク。Space を消すと、中の Task も一緒に消えます（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.space)
    var tasks: [TaskItem] = []

    init(name: String, symbolName: String, plan: PlanRect) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.plan = plan
    }

    var openTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
}

/// 間取り図の上で、Space が占める位置と大きさ。
///
/// 値はすべて 0〜1 の割合です（x: 0 が左端、y: 0 が上端）。
/// ポイント数ではなく割合で持つことで、画面サイズが違っても同じ間取りに見えます。
///
/// `Codable` にしておくと、SwiftData が Space の一部としてそのまま保存してくれます。
///
/// `nonisolated` は「メインスレッド以外からも使ってよい」という印です。
/// このプロジェクトは型をデフォルトでメインスレッド専用にする設定なので、
/// SwiftData が裏側で保存するときにも触れるよう、明示的に外しています。
nonisolated struct PlanRect: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
