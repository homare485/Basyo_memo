import Foundation
import SwiftData

/// Place の中にある「空間」。Kitchen / Library / Desk など。
@Model
final class Space {
    var id: UUID
    var name: String
    var symbolName: String

    /// 部屋の大きさ（小・中・大）。間取りの上でどれだけのマスを使うかを決めます。
    ///
    /// 初期値を付けているのは、古い形のデータベースが残っていても
    /// 起動時に読み込みに失敗しないようにするためです。
    var size: RoomSize = RoomSize.small

    /// 部屋を追加した順番。間取りは、この順に上から空いている場所へ詰めて並べます。
    /// SwiftData のリレーション（Place.spaces）は順番を保証しないので、自分で持ちます。
    var sortIndex: Int = 0

    /// この空間が属する場所。
    var place: Place?

    /// この空間に置かれているタスク。Space を消すと、中の Task も一緒に消えます（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.space)
    var tasks: [TaskItem] = []

    init(name: String, symbolName: String, size: RoomSize, sortIndex: Int) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.size = size
        self.sortIndex = sortIndex
    }

    var openTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
}

/// 部屋の大きさ。間取りは横2列のマス目で、大きさごとに使うマスが決まっています。
///
///     小 = 1マス    中 = 縦2マス    大 = 横2 × 縦2
///
/// `nonisolated` は「メインスレッド以外からも使ってよい」という印です。
/// SwiftData が裏側で保存するときにも触れるよう、明示的に付けています。
nonisolated enum RoomSize: String, Codable, CaseIterable {
    case small
    case medium
    case large

    /// 横に使うマスの数。
    var columns: Int {
        self == .large ? 2 : 1
    }

    /// 縦に使うマスの数。
    var rows: Int {
        self == .small ? 1 : 2
    }

    var label: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "大"
        }
    }
}
