import CoreGraphics

/// 間取りの配置計算。
///
/// 部屋の位置はデータとして保存せず、「大きさ」と「追加した順番」から毎回ここで求めます。
/// 位置を保存しないので、部屋が重なったり、はみ出したりした状態は起こり得ません。
///
/// ルール:
/// - 横2列のマス目に、追加した順で「上から見て最初に入る場所」へ置く
/// - 既に置いた部屋は動かさない（新しい部屋は、入る空きがあればそこに入る）
/// - どの部屋も入らなかったマスは「空き」として残る
struct FloorPlanLayout {
    static let columnCount = 2

    /// マス目の上での、ひとつの部屋の位置（単位はマス）。
    struct Placement {
        let row: Int
        let column: Int
        let size: RoomSize
    }

    /// どの部屋も置かれていないマス。
    struct Hole: Hashable {
        let row: Int
        let column: Int
    }

    /// sizes と同じ順番で並んだ配置。
    let placements: [Placement]
    let holes: [Hole]
    /// 家全体の段数。
    let rowCount: Int

    init(sizes: [RoomSize]) {
        var occupied: Set<Hole> = []
        var placements: [Placement] = []

        func fits(_ size: RoomSize, row: Int, column: Int) -> Bool {
            guard column + size.columns <= Self.columnCount else { return false }
            for r in row..<(row + size.rows) {
                for c in column..<(column + size.columns) where occupied.contains(Hole(row: r, column: c)) {
                    return false
                }
            }
            return true
        }

        for size in sizes {
            // 上の段から、左から順に、入る場所を探す。
            // 段数に上限はないので、必ずどこかには入る。
            var row = 0
            search: while true {
                for column in 0..<Self.columnCount where fits(size, row: row, column: column) {
                    for r in row..<(row + size.rows) {
                        for c in column..<(column + size.columns) {
                            occupied.insert(Hole(row: r, column: c))
                        }
                    }
                    placements.append(Placement(row: row, column: column, size: size))
                    break search
                }
                row += 1
            }
        }

        // 部屋が1つもなくても、1段分の空きを見せる（そこから部屋を足せるように）。
        let rowCount = max(1, placements.map { $0.row + $0.size.rows }.max() ?? 0)

        var holes: [Hole] = []
        for row in 0..<rowCount {
            for column in 0..<Self.columnCount where !occupied.contains(Hole(row: row, column: column)) {
                holes.append(Hole(row: row, column: column))
            }
        }

        self.placements = placements
        self.holes = holes
        self.rowCount = rowCount
    }
}

/// マス目を、実際の画面上の大きさ（ポイント）に変換する。
///
/// 家の大きさは「ハイブリッド」で決めます:
/// - 4段までは標準の大きさ
/// - それを超えたら、外壁の大きさはそのままで、1段を低くして詰める
/// - 1段が下限（64pt）に達したら、それ以上は詰めず、家を下に伸ばす
struct FloorPlanMetrics {
    /// 家の標準の高さ ＝ 幅 × この値。
    static let standardHeightRatio: CGFloat = 1.1
    /// 標準の大きさに収める段数。
    static let standardRowCount: CGFloat = 4
    /// 1段の高さの下限。iPhone SE でも部屋名が読める高さ。
    static let minimumRowHeight: CGFloat = 64

    let columnWidth: CGFloat
    let rowHeight: CGFloat
    let size: CGSize

    init(width: CGFloat, rowCount: Int) {
        let standardHeight = width * Self.standardHeightRatio
        let maximumRowHeight = standardHeight / Self.standardRowCount
        let fittedRowHeight = standardHeight / CGFloat(rowCount)

        columnWidth = width / CGFloat(FloorPlanLayout.columnCount)
        rowHeight = min(maximumRowHeight, max(Self.minimumRowHeight, fittedRowHeight))
        size = CGSize(width: width, height: rowHeight * CGFloat(rowCount))
    }

    func rect(row: Int, column: Int, columns: Int, rows: Int) -> CGRect {
        CGRect(
            x: CGFloat(column) * columnWidth,
            y: CGFloat(row) * rowHeight,
            width: CGFloat(columns) * columnWidth,
            height: CGFloat(rows) * rowHeight
        )
    }
}
