import SwiftUI
import SwiftData

/// 画面2: Spatial View
///
/// Place の中を、簡易的な間取り図として見せる画面。
/// Space を行やセルとして並べるのではなく、「部屋」として壁で区切って配置します。
struct SpatialView: View {
    /// SwiftData のモデルは参照型なので、受け取った place 自体が常に最新です。
    /// Space Detail でタスクを完了して戻ると、間取りの点もそのまま減っています。
    let place: Place

    /// ズーム遷移で「押した部屋」と「開く画面」を結びつけるための名前空間。
    @Namespace private var zoomNamespace

    /// 入っていく先の Space。値が入ると Space Detail へ遷移する。
    @State private var enteredSpace: Space?

    /// いまフォーカスしている Space。
    /// 「どの部屋にいるか」をこの1つの値だけで表しておくと、
    /// 将来フォーカス移動の演出を足すときも、この値の変化に反応させるだけで済みます。
    @State private var focusedSpaceID: Space.ID?

    var body: some View {
        ZStack {
            AmbientBackground()
                // 部屋の外をタップするとフォーカスが外れる。
                .onTapGesture { focus(nil) }

            VStack(alignment: .leading, spacing: 0) {
                header

                FloorPlan(
                    spaces: place.spaces,
                    focusedSpaceID: focusedSpaceID,
                    namespace: zoomNamespace,
                    onSelect: select
                )
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity)

                caption
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // focusedSpaceID が変わるたびに、軽い選択のハプティクスを鳴らす。
        .sensoryFeedback(.selection, trigger: focusedSpaceID)
        // enteredSpaceID に値が入ったら、その Space の画面を開く。
        .navigationDestination(item: $enteredSpace) { space in
            SpaceDetailView(space: space)
                // タップした部屋がそのまま広がって、Space Detail になる。
                .navigationTransition(.zoom(sourceID: space.id, in: zoomNamespace))
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(place.name)
                .font(.system(size: 28, weight: .regular))
                .tracking(5)

            Text("\(place.spaces.count)つの空間 · やること \(place.openTaskCount)")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    // MARK: Caption

    /// 間取りの下の一行。いまどの部屋にいるかだけを静かに示します。
    private var caption: some View {
        Text(captionText)
            .font(.system(size: 13))
            .foregroundStyle(focusedSpace == nil ? .tertiary : .secondary)
            .contentTransition(.opacity)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .padding(.bottom, 20)
    }

    private var focusedSpace: Space? {
        place.spaces.first { $0.id == focusedSpaceID }
    }

    private var captionText: String {
        guard let space = focusedSpace else { return "空間を選んでください" }
        return space.openTaskCount == 0
            ? "\(space.name.uppercased()) — 片付いています"
            : "\(space.name.uppercased()) — やること \(space.openTaskCount)"
    }

    // MARK: Actions

    private func select(_ space: Space) {
        // 入る部屋にフォーカスを移してから入る。
        // 戻ってきたとき、さっきまでいた部屋が明るいまま残るので「どこから出てきたか」が分かります。
        focus(space.id)
        enteredSpace = space
    }

    private func focus(_ id: Space.ID?) {
        withAnimation(.snappy(duration: 0.28)) {
            focusedSpaceID = id
        }
    }
}

// MARK: - Floor Plan

/// 間取り図。PlanRect（0〜1 の割合）を、実際の表示サイズに変換して部屋を配置します。
private struct FloorPlan: View {
    let spaces: [Space]
    let focusedSpaceID: Space.ID?
    let namespace: Namespace.ID
    let onSelect: (Space) -> Void

    /// 間取り全体の 幅 : 高さ。iPhone の縦画面に収まる比率にしています。
    private let aspectRatio: CGFloat = 0.78

    /// 玄関の位置（下辺のうち、左から何割〜何割を開けるか）。
    private let entrance: ClosedRange<Double> = 0.2...0.36

    var body: some View {
        // GeometryReader で「いま使える大きさ」を受け取り、割合をポイントに変換します。
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                ForEach(spaces) { space in
                    let rect = space.plan.rect(in: size)

                    Button {
                        onSelect(space)
                    } label: {
                        RoomView(
                            space: space,
                            isFocused: space.id == focusedSpaceID,
                            isDimmed: focusedSpaceID != nil && space.id != focusedSpaceID
                        )
                    }
                    .buttonStyle(RoomButtonStyle())
                    .frame(width: rect.width, height: rect.height)
                    // この部屋を、ズーム遷移の「出発点」として登録する。
                    .matchedTransitionSource(id: space.id, in: namespace)
                    .position(x: rect.midX, y: rect.midY)
                }

                // 壁は部屋の上に一枚の図形として重ねます（理由は Walls のコメント参照）。
                Walls(rooms: spaces.map(\.plan))
                    .stroke(Color.primary.opacity(0.16), lineWidth: 1)
                    .allowsHitTesting(false)

                OuterWall(entrance: entrance)
                    .stroke(Color.primary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .square))
                    .allowsHitTesting(false)

                Text("ENTRANCE")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)
                    .position(
                        x: size.width * (entrance.lowerBound + entrance.upperBound) / 2,
                        y: size.height + 16
                    )
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Room

/// ひとつの部屋。枠線は持たず、床の色と中身だけを描きます。
private struct RoomView: View {
    let space: Space
    let isFocused: Bool
    let isDimmed: Bool

    var body: some View {
        // 上から順に「収まるか」を試し、最初に収まった方を表示する。
        // 小さい iPhone の狭い部屋（Toilet など）では、アイコンを省いて名前の大きさを保ちます。
        ViewThatFits(in: .vertical) {
            content(showsIcon: true)
            content(showsIcon: false)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.primary.opacity(isFocused ? 0.09 : 0.025))
        .opacity(isDimmed ? 0.4 : 1)
        // 部屋の余白部分もタップできるように、当たり判定を長方形全体にする。
        .contentShape(Rectangle())
    }

    private func content(showsIcon: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsIcon {
                Image(systemName: space.symbolName)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 4)
            } else {
                Spacer(minLength: 0)
            }

            TaskDots(count: space.openTaskCount)

            Text(space.name.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 8)
        }
    }
}

/// 部屋に「まだ置いてあるもの」。タスク1件 = 点1つ。
/// 数字ではなく点にしているのは、Task を主役にせず、部屋の散らかり具合として見せるためです。
private struct TaskDots: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(count, 6), id: \.self) { _ in
                Circle().frame(width: 4, height: 4)
            }
        }
        .foregroundStyle(.secondary)
    }
}

private struct RoomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Walls

/// 部屋どうしを仕切る内壁。
///
/// 部屋ごとに枠線を引くと、隣り合う部屋の線が二重に重なって濃くなってしまいます。
/// そこで全ての壁を「1つの Path」にまとめて一度に描いています。
/// 1つの Path 内で線が重なっても、濃さは変わりません。
///
/// また外周上の辺はここでは描かず、OuterWall に任せます（玄関の隙間を開けるため）。
private struct Walls: Shape {
    let rooms: [PlanRect]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let isOnBoundary = { (value: Double) in value < 0.001 || value > 0.999 }

        for room in rooms {
            let r = room.rect(in: rect.size)
            if !isOnBoundary(room.y) {
                path.move(to: CGPoint(x: r.minX, y: r.minY))
                path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            }
            if !isOnBoundary(room.y + room.height) {
                path.move(to: CGPoint(x: r.minX, y: r.maxY))
                path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            }
            if !isOnBoundary(room.x) {
                path.move(to: CGPoint(x: r.minX, y: r.minY))
                path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            }
            if !isOnBoundary(room.x + room.width) {
                path.move(to: CGPoint(x: r.maxX, y: r.minY))
                path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            }
        }
        return path
    }
}

/// 家の外壁。下辺に玄関の隙間を開けて、一周ぐるりと描きます。
private struct OuterWall: Shape {
    let entrance: ClosedRange<Double>

    func path(in rect: CGRect) -> Path {
        let gapStart = rect.minX + rect.width * entrance.lowerBound
        let gapEnd = rect.minX + rect.width * entrance.upperBound

        var path = Path()
        path.move(to: CGPoint(x: gapStart, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: gapEnd, y: rect.maxY))
        return path
    }
}

// MARK: - Helpers

private extension PlanRect {
    /// 0〜1 の割合を、実際の表示サイズ上の CGRect に変換する。
    func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: x * size.width,
            y: y * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }
}

#Preview {
    let container = ModelContainer.preview
    let home = try! container.mainContext.fetch(
        FetchDescriptor<Place>(sortBy: [SortDescriptor(\.sortIndex)])
    ).first!

    NavigationStack {
        SpatialView(place: home)
    }
    .modelContainer(container)
}
