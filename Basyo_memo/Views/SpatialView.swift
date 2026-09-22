import SwiftUI
import SwiftData
import UIKit

/// 画面2: Spatial View
///
/// Place の中を、簡易的な間取り図として見せる画面。
/// Space を行やセルとして並べるのではなく、「部屋」として壁で区切って配置します。
struct SpatialView: View {
    /// SwiftData のモデルは参照型なので、受け取った place 自体が常に最新です。
    /// Space Detail でタスクを完了して戻ると、間取りの点もそのまま減っています。
    let place: Place

    @Environment(\.modelContext) private var modelContext

    /// ズーム遷移で「押した部屋」と「開く画面」を結びつけるための名前空間。
    @Namespace private var zoomNamespace

    /// 入っていく先の Space。値が入ると Space Detail へ遷移する。
    @State private var enteredSpace: Space?

    /// いまフォーカスしている Space。
    /// 「どの部屋にいるか」をこの1つの値だけで表しておくと、
    /// 将来フォーカス移動の演出を足すときも、この値の変化に反応させるだけで済みます。
    @State private var focusedSpaceID: Space.ID?

    /// 部屋を追加するシートを開いているか。
    @State private var isAddingRoom = false

    /// 削除の確認中の部屋。値が入ると確認ダイアログが出る。
    @State private var spacePendingDeletion: Space?

    /// 間取りに使える横幅。画面の幅から左右の余白を引いたもの。
    @State private var planWidth: CGFloat = 0

    /// 追加した順に並べた部屋。間取りはこの順で上から詰めていきます。
    private var sortedSpaces: [Space] {
        place.spaces.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            // 部屋を足していくと家が下に伸びるので、全体をスクロールできるようにする。
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if planWidth > 0 {
                        FloorPlan(
                            spaces: sortedSpaces,
                            width: planWidth,
                            focusedSpaceID: focusedSpaceID,
                            namespace: zoomNamespace,
                            onSelect: select,
                            onDelete: { spacePendingDeletion = $0 },
                            onAddRoom: { isAddingRoom = true }
                        )
                        .padding(.horizontal, 20)
                    }

                    caption
                }
                // 部屋の外（余白）をタップするとフォーカスが外れる。
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { focus(nil) }
                )
            }
            .scrollIndicators(.hidden)
            // 画面の幅が分かったら、間取りの横幅を決める。
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                planWidth = width - 40
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingRoom = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("部屋を追加")
            }
        }
        // focusedSpaceID が変わるたびに、軽い選択のハプティクスを鳴らす。
        .sensoryFeedback(.selection, trigger: focusedSpaceID)
        // 部屋が増えた・減ったときの、ごく軽い手応え。
        .sensoryFeedback(.impact(weight: .light), trigger: place.spaces.count)
        // enteredSpace に値が入ったら、その Space の画面を開く。
        .navigationDestination(item: $enteredSpace) { space in
            SpaceDetailView(space: space)
                // タップした部屋がそのまま広がって、Space Detail になる。
                .navigationTransition(.zoom(sourceID: space.id, in: zoomNamespace))
        }
        .sheet(isPresented: $isAddingRoom) {
            AddRoomView(place: place)
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { spacePendingDeletion != nil },
                set: { if !$0 { spacePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: spacePendingDeletion
        ) { space in
            Button("削除", role: .destructive) { delete(space) }
        } message: { space in
            Text(space.openTaskCount == 0
                 ? "この操作は取り消せません。"
                 : "中にある、やること \(space.openTaskCount) 件も一緒に削除されます。この操作は取り消せません。")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(place.displayName)
                .font(.system(size: 28, weight: .regular))
                .tracking(5)

            Text(place.spaces.isEmpty
                 ? "部屋はまだありません"
                 : "\(place.spaces.count)つの空間 · やること \(place.openTaskCount)")
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
            .padding(.top, 36)
            .padding(.bottom, 24)
    }

    private var focusedSpace: Space? {
        place.spaces.first { $0.id == focusedSpaceID }
    }

    private var captionText: String {
        // 部屋が1つもない場所では、「選んで」ではなく「つくれる」ことを伝える。
        if place.spaces.isEmpty { return "＋ から部屋をつくれます" }
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

    private var deletionTitle: String {
        "「\(spacePendingDeletion?.name.uppercased() ?? "")」を削除しますか？"
    }

    private func delete(_ space: Space) {
        // 削除すると、後ろの部屋が空いた場所へ詰めて動く。その動きをアニメーションにする。
        withAnimation(.snappy(duration: 0.35)) {
            if focusedSpaceID == space.id {
                focusedSpaceID = nil
            }
            // Space を消すと、中の Task も一緒に消えます（モデルの .cascade 設定）。
            modelContext.delete(space)
            try? modelContext.save()
        }
    }

    private func focus(_ id: Space.ID?) {
        withAnimation(.snappy(duration: 0.28)) {
            focusedSpaceID = id
        }
    }
}

// MARK: - Floor Plan

/// 間取り図。部屋の大きさと順番から配置を計算し（FloorPlanLayout）、ポイントに変換して並べます。
private struct FloorPlan: View {
    let spaces: [Space]
    let width: CGFloat
    let focusedSpaceID: Space.ID?
    let namespace: Namespace.ID
    let onSelect: (Space) -> Void
    let onDelete: (Space) -> Void
    let onAddRoom: () -> Void

    /// 部屋どうしを仕切る壁の色。
    /// 隣り合う部屋の枠線はぴったり同じ位置に重なるので、半透明だと重なった所だけ濃くなります。
    /// 不透明な色（systemGray4）にして、重なっても濃さが変わらないようにしています。
    private let wallColor = Color(uiColor: .systemGray4)

    var body: some View {
        let layout = FloorPlanLayout(sizes: spaces.map(\.size))
        let metrics = FloorPlanMetrics(width: width, rowCount: layout.rowCount)

        ZStack {
            // 空いているマス。タップすると部屋を追加できる。
            ForEach(layout.holes, id: \.self) { hole in
                let rect = metrics.rect(row: hole.row, column: hole.column, columns: 1, rows: 1)

                Button(action: onAddRoom) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(.tertiary)
                        .frame(width: rect.width, height: rect.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(RoomButtonStyle())
                .accessibilityLabel("部屋を追加")
                .position(x: rect.midX, y: rect.midY)
                .transition(.opacity)
            }

            ForEach(Array(zip(spaces, layout.placements)), id: \.0.id) { space, placement in
                let rect = metrics.rect(
                    row: placement.row,
                    column: placement.column,
                    columns: placement.size.columns,
                    rows: placement.size.rows
                )

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
                // 壁は部屋ごとに持たせる。部屋が詰めて動くとき、壁も一緒に動くようにするためです。
                .overlay(Rectangle().stroke(wallColor, lineWidth: 1))
                // この部屋を、ズーム遷移の「出発点」として登録する。
                .matchedTransitionSource(id: space.id, in: namespace)
                // 長押しで出るメニュー。
                .contextMenu {
                    Button(role: .destructive) {
                        onDelete(space)
                    } label: {
                        Label("部屋を削除", systemImage: "trash")
                    }
                }
                .position(x: rect.midX, y: rect.midY)
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            // 外壁。部屋の枠線より太く、濃く。
            Rectangle()
                .stroke(Color.primary.opacity(0.5), lineWidth: 1.5)
                .allowsHitTesting(false)
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
    }
}

// MARK: - Room

/// ひとつの部屋の床と中身。壁（枠線）は FloorPlan の側で重ねます。
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
