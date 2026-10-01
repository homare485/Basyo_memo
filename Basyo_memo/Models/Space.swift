import Foundation
import SwiftData

/// Place の中にある「空間」。Kitchen / Library / Desk など。
@Model
final class Space {
    var id: UUID
    var name: String
    var symbolName: String

    /// 部屋の大きさ（小・中・大）。
    ///
    /// いまの間取りは、下の gridColumn などに「位置と大きさ」をそのまま保存しています。
    /// これは「位置をまだ持っていない古い部屋」を最初に置くときの目安にだけ使います。
    /// 初期値を付けているのは、古い形のデータベースが残っていても
    /// 起動時に読み込みに失敗しないようにするためです。
    var size: RoomSize = RoomSize.small

    /// 部屋を追加した順番。
    /// SwiftData のリレーション（Place.spaces）は順番を保証しないので、自分で持ちます。
    var sortIndex: Int = 0

    // MARK: 間取りの上の位置と大きさ（単位はマス）

    /// 左端の列。-1 は「まだ置かれていない」印（このバージョンより前に作った部屋）。
    /// どれも初期値を付けているので、古いデータベースもそのまま読み込めます。
    var gridColumn: Int = -1
    /// 上端の段。
    var gridRow: Int = 0
    /// 横に使うマスの数。
    var gridWidth: Int = 0
    /// 縦に使うマスの数。
    var gridHeight: Int = 0

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

    /// 間取りの上の位置と大きさ。まだ置かれていなければ nil。
    var gridRect: GridRect? {
        guard gridColumn >= 0, gridWidth > 0, gridHeight > 0 else { return nil }
        return GridRect(column: gridColumn, row: gridRow, width: gridWidth, height: gridHeight)
    }

    /// 間取りの上の位置と大きさを書き込む。
    func setGridRect(_ rect: GridRect) {
        gridColumn = rect.column
        gridRow = rect.row
        gridWidth = rect.width
        gridHeight = rect.height
    }
}

extension Place {
    /// 位置をまだ持っていない部屋（前のバージョンで作った部屋や、サンプル）を、空いている所へ置く。
    ///
    /// 置き方は以前の自動の並べ方と同じです（追加した順に、上から・左から、最初に入る空きへ）。
    /// なので、アップデートしても今までの間取りの見た目はそのまま残ります。
    /// - Returns: 1つでも置いた部屋があれば true（呼び出し側で保存するため）。
    @discardableResult
    func placeUnplacedRooms() -> Bool {
        let ordered = spaces.sorted { $0.sortIndex < $1.sortIndex }
        var taken: [GridRect] = []
        for space in ordered {
            if let rect = space.gridRect {
                taken.append(rect)
            }
        }

        var didPlace = false
        for space in ordered where space.gridRect == nil {
            let rect = FloorGrid.firstFreeRect(
                width: space.size.defaultGridWidth,
                height: space.size.defaultGridHeight,
                among: taken
            )
            space.setGridRect(rect)
            taken.append(rect)
            didPlace = true
        }
        return didPlace
    }
}

/// 部屋の大きさ（前のバージョンの考え方）。以前の間取りは横2列のマス目で、
///
///     小 = 1マス    中 = 縦2マス    大 = 横2 × 縦2
///
/// いまは部屋ごとに自由な大きさを持てます。これは古い部屋を置き直すときの目安です。
///
/// `nonisolated` は「メインスレッド以外からも使ってよい」という印です。
/// SwiftData が裏側で保存するときにも触れるよう、明示的に付けています。
nonisolated enum RoomSize: String, Codable, CaseIterable {
    case small
    case medium
    case large

    /// 以前の間取りで、横に使うマスの数。
    var columns: Int {
        self == .large ? 2 : 1
    }

    /// 以前の間取りで、縦に使うマスの数。
    var rows: Int {
        self == .small ? 1 : 2
    }

    /// いまのマス目での横幅。以前の1マス（横半分）は、いまの横3マス × 縦2マスにあたります。
    /// こうしておくと、前のバージョンで作った間取りが、ほぼ同じ見た目のまま引き継がれます。
    var defaultGridWidth: Int {
        columns * 3
    }

    /// いまのマス目での高さ。
    var defaultGridHeight: Int {
        rows * 2
    }

    /// 自由な大きさから、いちばん近い「小・中・大」を選ぶ（古い項目を埋めておくためだけ）。
    static func approximating(width: Int, height: Int) -> RoomSize {
        if width >= 4 && height >= 4 { return .large }
        if height >= 4 { return .medium }
        return .small
    }

    /// 画面に出す表記。端末の言語に合わせて翻訳されます。
    var label: String {
        switch self {
        case .small: String(localized: "小")
        case .medium: String(localized: "中")
        case .large: String(localized: "大")
        }
    }
}
