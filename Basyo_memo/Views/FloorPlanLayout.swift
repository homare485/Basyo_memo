import CoreGraphics

/// 間取りのマス目の上での、ひとつの部屋の位置と大きさ（単位はマス）。
///
/// 以前は「大きさ」と「追加した順番」から位置を毎回計算していましたが、
/// ユーザーが自分で部屋を置けるように、いまは位置と大きさを Space に保存しています。
nonisolated struct GridRect: Hashable {
    var column: Int
    var row: Int
    var width: Int
    var height: Int

    /// 右端のすぐ外の列（この列は含まない）。
    var maxColumn: Int {
        column + width
    }

    /// 下端のすぐ外の段（この段は含まない）。
    var maxRow: Int {
        row + height
    }

    /// 1マスでも重なっているか。辺どうしが接しているだけなら、重なりではありません。
    func intersects(_ other: GridRect) -> Bool {
        let overlapsHorizontally = column < other.maxColumn && other.column < maxColumn
        let overlapsVertically = row < other.maxRow && other.row < maxRow
        return overlapsHorizontally && overlapsVertically
    }
}

/// 間取りのマス目のきまり。
///
/// 家（外壁の枠）の中を、横 `columnCount` 列の正方形のマス目に分けています。
/// 編集画面ではこのマス目の角に点を打ち、部屋の角はその点に吸い付きます。
/// 点をもっと細かくしたいときは `columnCount` を変えるだけです。
nonisolated enum FloorGrid {
    /// 横のマスの数。
    static let columnCount = 6

    /// 部屋のいちばん小さい大きさ（マス）。これより小さいと部屋の名前が読めなくなります。
    static let minimumWidth = 2
    static let minimumHeight = 2

    /// 部屋が少なくても、家らしい形に見えるように確保する段数。
    static let minimumRowCount = 6

    /// 編集中は、いちばん下の部屋の下にこれだけ空きの段を出す。家を下へ伸ばせるように。
    static let editingExtraRows = 3

    /// 家を下へ伸ばせる上限。
    static let maximumRowCount = 60

    /// 表示する家の段数。
    static func rowCount(for rects: [GridRect]) -> Int {
        var bottom = 0
        for rect in rects {
            bottom = max(bottom, rect.maxRow)
        }
        return max(minimumRowCount, bottom)
    }

    /// 家の枠の中に収まっていて、小さすぎないか。
    static func isInBounds(_ rect: GridRect) -> Bool {
        rect.column >= 0
            && rect.row >= 0
            && rect.maxColumn <= columnCount
            && rect.maxRow <= maximumRowCount
            && rect.width >= minimumWidth
            && rect.height >= minimumHeight
    }

    /// この位置に置けるか（枠からはみ出さず、他の部屋と重ならない）。
    static func canPlace(_ rect: GridRect, among others: [GridRect]) -> Bool {
        guard isInBounds(rect) else { return false }
        for other in others where other.intersects(rect) {
            return false
        }
        return true
    }

    /// 上から・左から見て、最初に入る空き。新しい部屋の最初の位置や、古い部屋を置き直すときに使います。
    static func firstFreeRect(width requestedWidth: Int, height requestedHeight: Int,
                              among others: [GridRect]) -> GridRect {
        let width = min(max(requestedWidth, minimumWidth), columnCount)
        let height = max(requestedHeight, minimumHeight)

        var bottom = 0
        for other in others {
            bottom = max(bottom, other.maxRow)
        }

        // いちばん下の部屋より下は必ず空いているので、bottom の段までで必ず見つかります。
        for row in 0...bottom {
            for column in 0...(columnCount - width) {
                let rect = GridRect(column: column, row: row, width: width, height: height)
                if canPlace(rect, among: others) {
                    return rect
                }
            }
        }
        return GridRect(column: 0, row: bottom, width: width, height: height)
    }

    /// 動かしている部屋（moving）に重なった部屋を、下へ押し出す。
    ///
    /// 上にある部屋から順に見ていき、何かに重なっていたら、その下端まで下げます。
    /// 下げた先でまた別の部屋に重なれば、さらに下へ。こうして玉突きのように下へずれていきます。
    /// 横の位置と大きさは変えません。
    ///
    /// いつも「元の位置」から計算し直すので、部屋を離せば、押し出された部屋も元の位置に戻ります。
    /// - Returns: others と同じ順番で並んだ、押し出した後の位置。
    static func pushDown(_ others: [GridRect], awayFrom moving: GridRect) -> [GridRect] {
        let order = others.indices.sorted { a, b in
            if others[a].row != others[b].row {
                return others[a].row < others[b].row
            }
            return others[a].column < others[b].column
        }

        var result = others
        var settled: [GridRect] = [moving]

        for index in order {
            var candidate = others[index]
            var didMove = true
            while didMove {
                didMove = false
                for blocker in settled where blocker.intersects(candidate) {
                    candidate.row = blocker.maxRow
                    didMove = true
                    break
                }
            }
            result[index] = candidate
            settled.append(candidate)
        }
        return result
    }

    /// 値を lower...upper の間に収める。
    static func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
        min(max(value, lower), max(lower, upper))
    }
}

// MARK: - Metrics

/// マス目を、実際の画面上の大きさ（ポイント）に変換する。
///
/// マスは正方形。家の横幅を列の数で割ったものが1マスの大きさです。
/// 部屋を下に足していくと、家もそのぶん下に伸びます。
nonisolated struct FloorPlanMetrics {
    let cellSize: CGFloat
    let rowCount: Int
    let size: CGSize

    init(width: CGFloat, rowCount: Int) {
        let cell = width / CGFloat(FloorGrid.columnCount)
        self.cellSize = cell
        self.rowCount = rowCount
        self.size = CGSize(width: width, height: cell * CGFloat(rowCount))
    }

    func rect(for grid: GridRect) -> CGRect {
        CGRect(
            x: CGFloat(grid.column) * cellSize,
            y: CGFloat(grid.row) * cellSize,
            width: CGFloat(grid.width) * cellSize,
            height: CGFloat(grid.height) * cellSize
        )
    }
}
