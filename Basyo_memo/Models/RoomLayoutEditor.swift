import SwiftUI
import SwiftData
import UIKit

// MARK: - Placed Room

/// 編集画面で薄く見せる「他の部屋」。表示に必要な最小限の情報だけを持ちます。
struct PlacedRoom: Identifiable {
    let id: UUID
    let name: String
    let rect: GridRect

    /// その場所にある部屋のうち、位置を持っているものを集める。excludedID の部屋は除く。
    static func rooms(in place: Place?, excluding excludedID: UUID? = nil) -> [PlacedRoom] {
        guard let place else { return [] }
        var result: [PlacedRoom] = []
        for space in place.spaces {
            if let excludedID, space.id == excludedID { continue }
            if let rect = space.gridRect {
                result.append(PlacedRoom(id: space.id, name: space.name, rect: rect))
            }
        }
        return result
    }

    /// rect に置く部屋に重なった部屋を、下へ押し出した後の並び（rooms と同じ順番）。
    static func makingRoom(for rect: GridRect, in rooms: [PlacedRoom]) -> [PlacedRoom] {
        let pushed = FloorGrid.pushDown(rooms.map { $0.rect }, awayFrom: rect)
        var result: [PlacedRoom] = []
        for (index, room) in rooms.enumerated() {
            result.append(PlacedRoom(id: room.id, name: room.name, rect: pushed[index]))
        }
        return result
    }

    /// 押し出した後の位置を、その場所の実際の部屋に書き込む。
    static func apply(_ rooms: [PlacedRoom], to place: Place?) {
        guard let place else { return }
        for space in place.spaces {
            guard let room = rooms.first(where: { $0.id == space.id }) else { continue }
            if space.gridRect != room.rect {
                space.setGridRect(room.rect)
            }
        }
    }
}

// MARK: - Editor

/// 部屋の位置と大きさを決める編集画面。
///
/// 家の枠の中に、マス目の角ごとに点を打って見せます。
/// 部屋はドラッグで動かし、右下の角をつまんで大きさを変えます。どちらも点に吸い付くので、
/// 「横いくつ・縦いくつ分の部屋にするか」が点の数で分かります。
///
/// 他の部屋は直接は動かせません。動かしている部屋が重なると、重なった部屋が下へ押し出されます。
struct RoomLayoutEditor: View {
    /// すでに置かれている、他の部屋（元の位置）。
    let others: [PlacedRoom]
    /// 動かしている部屋の位置と大きさ（単位はマス）。
    @Binding var rect: GridRect
    let name: String
    let symbolName: String

    /// 編集画面の横幅。画面の大きさが分かってから決まります。
    @State private var editorWidth: CGFloat = 0

    /// ドラッグを始めたときの位置と大きさ。指の移動量をこれに足して、新しい位置を決めます。
    @State private var dragStart: GridRect?

    /// 動かしている部屋に押し出された後の、他の部屋。
    private var arrangedOthers: [PlacedRoom] {
        PlacedRoom.makingRoom(for: rect, in: others)
    }

    /// 押し出されて、元の位置からずれた部屋の数。
    private var pushedCount: Int {
        var count = 0
        for (original, arranged) in zip(others, arrangedOthers) where original.rect != arranged.rect {
            count += 1
        }
        return count
    }

    /// 家の枠に収まっているか（重なりは押し出すので、ここでは見ない）。
    private var canPlace: Bool {
        FloorGrid.isInBounds(rect)
    }

    /// 枠の段数。いちばん下の部屋より少し下まで見せて、家を下へ伸ばせるようにします。
    private var rowCount: Int {
        var bottom = rect.maxRow
        for other in arrangedOthers {
            bottom = max(bottom, other.rect.maxRow)
        }
        return max(FloorGrid.minimumRowCount, bottom + FloorGrid.editingExtraRows)
    }

    var body: some View {
        let metrics = FloorPlanMetrics(width: editorWidth, rowCount: rowCount)

        VStack(alignment: .leading, spacing: 12) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: editorWidth > 0 ? metrics.size.height : 240)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newWidth in
                    editorWidth = newWidth
                }
                .overlay(alignment: .topLeading) {
                    if editorWidth > 0 {
                        floorPlan(metrics)
                    }
                }

            hint
        }
        .animation(.snappy(duration: 0.2), value: rowCount)
        // 部屋が1マス動くたび・大きさが1マス変わるたびに、軽く手応えを返す。
        .sensoryFeedback(.selection, trigger: rect)
    }

    // MARK: Floor

    /// 指の位置を、部屋ではなく家の枠を基準に測るための名前。
    /// 部屋自身を基準にすると、部屋が動くたびに基準もずれて、動きががたつきます。
    private static let floorSpaceName = "RoomLayoutEditor.floor"

    private func floorPlan(_ metrics: FloorPlanMetrics) -> some View {
        let roomFrame = metrics.rect(for: rect)

        return ZStack(alignment: .topLeading) {
            // 床。
            Rectangle()
                .fill(Color.primary.opacity(0.025))

            // マス目の角の点。
            GridDots(metrics: metrics, highlighted: rect)

            // 他の部屋。重なった部屋は、下へ押し出された位置に出る。
            ForEach(Array(zip(others, arrangedOthers)), id: \.0.id) { original, arranged in
                OtherRoom(
                    name: arranged.name,
                    frame: metrics.rect(for: arranged.rect),
                    isPushed: original.rect != arranged.rect
                )
            }

            // 動かしている部屋。
            movingRoom(size: roomFrame.size, cellSize: metrics.cellSize)
                .position(x: roomFrame.midX, y: roomFrame.midY)

            // 外壁。間取り図（Spatial View）と同じ太さ・濃さ。
            Rectangle()
                .stroke(Color.primary.opacity(0.5), lineWidth: 1.5)
                .allowsHitTesting(false)
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
        .coordinateSpace(.named(Self.floorSpaceName))
    }

    // MARK: Moving Room

    private func movingRoom(size: CGSize, cellSize: CGFloat) -> some View {
        MovingRoomLabel(name: name, symbolName: symbolName, rect: rect, isValid: canPlace)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(moveGesture(cellSize: cellSize))
            .overlay(alignment: .bottomTrailing) {
                ResizeHandle(isValid: canPlace)
                    // 角の上に、半分はみ出すように置く。
                    .offset(x: 11, y: 11)
                    .gesture(resizeGesture(cellSize: cellSize))
            }
    }

    // MARK: Gestures

    /// 部屋を動かす。指の移動量を「何マス分か」に丸めて、点に吸い付かせます。
    private func moveGesture(cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.floorSpaceName))
            .onChanged { value in
                let start = dragStart ?? rect
                if dragStart == nil {
                    dragStart = rect
                }

                let movedColumns = cellCount(value.translation.width, cellSize: cellSize)
                let movedRows = cellCount(value.translation.height, cellSize: cellSize)

                var next = start
                next.column = FloorGrid.clamp(start.column + movedColumns,
                                              0, FloorGrid.columnCount - start.width)
                next.row = FloorGrid.clamp(start.row + movedRows,
                                           0, FloorGrid.maximumRowCount - start.height)
                update(to: next)
            }
            .onEnded { _ in
                dragStart = nil
            }
    }

    /// 部屋の大きさを変える。左上の角は動かさず、右下の角だけを動かします。
    private func resizeGesture(cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.floorSpaceName))
            .onChanged { value in
                let start = dragStart ?? rect
                if dragStart == nil {
                    dragStart = rect
                }

                let addedColumns = cellCount(value.translation.width, cellSize: cellSize)
                let addedRows = cellCount(value.translation.height, cellSize: cellSize)

                var next = start
                next.width = FloorGrid.clamp(start.width + addedColumns,
                                             FloorGrid.minimumWidth, FloorGrid.columnCount - start.column)
                next.height = FloorGrid.clamp(start.height + addedRows,
                                              FloorGrid.minimumHeight, FloorGrid.maximumRowCount - start.row)
                update(to: next)
            }
            .onEnded { _ in
                dragStart = nil
            }
    }

    private func update(to next: GridRect) {
        guard next != rect else { return }
        withAnimation(.snappy(duration: 0.15)) {
            rect = next
        }
    }

    /// 指の移動量（ポイント）を、いちばん近いマスの数に丸める。
    private func cellCount(_ distance: CGFloat, cellSize: CGFloat) -> Int {
        guard cellSize > 0 else { return 0 }
        return Int((distance / cellSize).rounded())
    }

    // MARK: Hint

    private var hint: some View {
        VStack(spacing: 4) {
            Text("ドラッグで移動 · 右下の角で大きさを変える")
                .foregroundStyle(.tertiary)

            if pushedCount > 0 {
                Text("重なった部屋は、下へずらします")
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.15), value: pushedCount > 0)
    }
}

// MARK: - Parts

/// マス目の角ごとの点。動かしている部屋が覆っている点だけ、少し濃くします。
private struct GridDots: View {
    let metrics: FloorPlanMetrics
    let highlighted: GridRect

    var body: some View {
        // Canvas の中では、先に取り出しておいた値だけを使う。
        let cellSize = metrics.cellSize
        let lastRow = metrics.rowCount
        let lastColumn = FloorGrid.columnCount
        let area = highlighted

        Canvas { context, _ in
            let diameter: CGFloat = 3
            for row in 0...lastRow {
                for column in 0...lastColumn {
                    let isInside = column >= area.column && column <= area.maxColumn
                        && row >= area.row && row <= area.maxRow
                    let x = CGFloat(column) * cellSize
                    let y = CGFloat(row) * cellSize
                    let dot = Path(ellipseIn: CGRect(x: x - diameter / 2, y: y - diameter / 2,
                                                     width: diameter, height: diameter))
                    let opacity: Double = isInside ? 0.55 : 0.22
                    context.fill(dot, with: .color(Color.primary.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// 動かしている部屋の中身。
private struct MovingRoomLabel: View {
    let name: String
    let symbolName: String
    let rect: GridRect
    let isValid: Bool

    var body: some View {
        let tint: Color = isValid ? Color.primary : Color.red

        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            Text(name.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // 横×縦のマスの数。
            Text(verbatim: "\(rect.width) × \(rect.height)")
                .font(.system(size: 10))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(tint.opacity(isValid ? 0.1 : 0.12))
        .overlay(
            Rectangle().strokeBorder(tint.opacity(isValid ? 0.8 : 1), lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(name)、横\(rect.width)マス、縦\(rect.height)マス"))
    }
}

/// 右下の角。ここをつまんで大きさを変えます。
private struct ResizeHandle: View {
    let isValid: Bool

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(width: 22, height: 22)
            .background(Circle().fill(isValid ? Color.primary : Color.red))
            // 指で押しやすいよう、見た目より広い範囲で反応させる。
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

/// 編集中に薄く見せる、他の部屋。押し出された部屋は、枠を少し濃くして「動いた」ことを示します。
private struct OtherRoom: View {
    let name: String
    let frame: CGRect
    let isPushed: Bool

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: 10, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(8)
            .frame(width: frame.width, height: frame.height, alignment: .bottomLeading)
            .background(Color.primary.opacity(isPushed ? 0.08 : 0.05))
            .overlay(
                Rectangle().stroke(
                    isPushed ? Color.primary.opacity(0.35) : Color(uiColor: .systemGray4),
                    style: StrokeStyle(lineWidth: 1, dash: isPushed ? [4, 3] : [])
                )
            )
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
    }
}

// MARK: - Arrange Room

/// すでにある部屋の、位置と大きさを変えるシート。間取り図で部屋を長押しすると開きます。
struct ArrangeRoomView: View {
    let space: Space

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var rect: GridRect

    init(space: Space) {
        self.space = space
        let fallback = GridRect(column: 0, row: 0,
                                width: space.size.defaultGridWidth,
                                height: space.size.defaultGridHeight)
        _rect = State(initialValue: space.gridRect ?? fallback)
    }

    private var others: [PlacedRoom] {
        PlacedRoom.rooms(in: space.place, excluding: space.id)
    }

    /// 家の枠に収まっているか（重なった部屋は押し出すので、重なりは見ない）。
    private var canPlace: Bool {
        FloorGrid.isInBounds(rect)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    location

                    Text("配置を変える")
                        .font(.system(size: 22, weight: .light))
                        .padding(.top, 22)
                        .padding(.bottom, 24)

                    RoomLayoutEditor(
                        others: others,
                        rect: $rect,
                        name: space.name,
                        symbolName: space.symbolName
                    )
                }
                .padding(28)
            }
            .scrollIndicators(.hidden)

            actions
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
        }
        .presentationDetents([.large])
        .presentationBackground(Color(uiColor: .systemBackground))
        // 下にスワイプして閉じようとした指が、部屋のドラッグと取り合わないように。
        .interactiveDismissDisabled()
    }

    private var location: some View {
        HStack(spacing: 8) {
            if let place = space.place {
                Text(place.displayName)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
            }
            Text(space.name.uppercased())
        }
        .font(.system(size: 11, weight: .medium))
        .tracking(2)
        .foregroundStyle(.tertiary)
    }

    private var actions: some View {
        HStack {
            Button("キャンセル") { dismiss() }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(Capsule().fill(Color.primary.opacity(canPlace ? 1 : 0.15)))
            }
            .buttonStyle(.plain)
            .disabled(!canPlace)
            .animation(.easeOut(duration: 0.15), value: canPlace)
        }
    }

    private func save() {
        guard canPlace else { return }
        let arranged = PlacedRoom.makingRoom(for: rect, in: others)
        withAnimation(.snappy(duration: 0.35)) {
            // 重なっていた部屋を、押し出した先へ動かす。
            PlacedRoom.apply(arranged, to: space.place)
            space.setGridRect(rect)
            space.size = RoomSize.approximating(width: rect.width, height: rect.height)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = ModelContainer.preview
    let kitchen = try! container.mainContext.fetch(
        FetchDescriptor<Space>(predicate: #Predicate { $0.name == "Kitchen" })
    ).first!

    Color.clear
        .sheet(isPresented: .constant(true)) {
            ArrangeRoomView(space: kitchen)
        }
        .modelContainer(container)
}
