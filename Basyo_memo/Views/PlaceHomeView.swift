import SwiftUI
import SwiftData

/// 画面1: Place Home
///
/// いま選んでいる場所を大きなカードで見せ、残りの場所をその下に小さく並べます。
/// 大きなカードは横にスライドして切り替えられ、タップするとその場所の中に入ります。
struct PlaceHomeView: View {
    /// データベースから Place を読み、sortIndex 順に並べる。
    /// @Query はデータが変わると自動で読み直してくれます。
    @Query(sort: \Place.sortIndex) private var places: [Place]

    @Environment(\.modelContext) private var modelContext
    @Environment(ProAccess.self) private var pro

    /// 最後に中へ入った場所。次に起動したとき、この場所を大きなカードで出します。
    ///
    /// `@AppStorage` は、小さな値を端末に保存する仕組み（UserDefaults）です。
    /// アプリを終了しても残ります。UUID はそのまま保存できないので文字列にしています。
    @AppStorage("lastOpenedPlaceID") private var lastOpenedPlaceID = ""

    /// ズーム遷移で「押したカード」と「開く画面」を結びつけるための名前空間。
    @Namespace private var zoomNamespace

    /// 大きなカードで表示中の場所。横スクロールの位置と連動しています。
    @State private var currentPlaceID: Place.ID?

    /// 中に入っていく場所。値が入ると Spatial View へ遷移する。
    @State private var enteredPlace: Place?

    @State private var isAddingPlace = false

    /// Pro の案内を開いているか。
    @State private var isShowingPaywall = false

    /// Pro の案内で購入が済んだら、案内を閉じたあとに場所の追加へ進む。
    @State private var shouldAddPlaceAfterPaywall = false

    /// 追加した直後の場所。一覧に現れたら、そこまでスライドします。
    @State private var pendingPlaceID: Place.ID?

    /// 削除の確認中の場所。
    @State private var placePendingDeletion: Place?

    /// 新しい場所を作れるか。無料では3つまで。Pro なら無制限。
    /// すでに4つ以上ある無料の利用者も、今ある場所はそのまま使え、新しく足すときだけ案内が出ます。
    private var canAddPlace: Bool {
        pro.isPro || places.count < PurchaseConfig.freePlaceLimit
    }

    /// 大きなカード以外の、残りの場所。
    private var otherPlaces: [Place] {
        places.filter { $0.id != currentPlaceID }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    if !places.isEmpty {
                        featuredPager
                        pageDots
                    }

                    VStack(spacing: 10) {
                        ForEach(otherPlaces) { place in
                            Button {
                                select(place)
                            } label: {
                                PlaceRow(place: place)
                            }
                            .buttonStyle(GatewayButtonStyle())
                            .contextMenu { menu(for: place) }
                        }
                    }
                    // 大きなカードが切り替わったとき、この列は動かさず、中身だけを短くフェードで入れ替える。
                    .id(currentPlaceID)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: currentPlaceID)
                    .padding(.horizontal, 20)

                    addPlaceButton
                        .padding(.horizontal, 20)
                        .padding(.top, otherPlaces.isEmpty ? 0 : 16)
                        .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        // この画面は独自の見出しを持つので、ナビゲーションバーは隠す。
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $enteredPlace) { place in
            SpatialView(place: place)
                // 押したカードがそのまま広がって、Spatial View になる。
                .navigationTransition(.zoom(sourceID: place.id, in: zoomNamespace))
        }
        .sheet(isPresented: $isAddingPlace) {
            AddPlaceView { newPlace in
                pendingPlaceID = newPlace.id
            }
        }
        .sheet(isPresented: $isShowingPaywall, onDismiss: {
            // シートを2枚同時には開けないので、Pro の案内が閉じきってから場所の追加を開く。
            if shouldAddPlaceAfterPaywall {
                shouldAddPlaceAfterPaywall = false
                isAddingPlace = true
            }
        }) {
            ProPaywallView {
                shouldAddPlaceAfterPaywall = true
            }
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { placePendingDeletion != nil },
                set: { if !$0 { placePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: placePendingDeletion
        ) { place in
            Button("削除", role: .destructive) { delete(place) }
        } message: { place in
            Text(deletionMessage(for: place))
        }
        .onAppear(perform: restoreSelection)
        // 場所が増えた・減ったとき、表示中の場所がなくなっていたら選び直す。
        .onChange(of: places.map(\.id)) { _, ids in
            if let pending = pendingPlaceID, ids.contains(pending) {
                pendingPlaceID = nil
                withAnimation(.snappy(duration: 0.4)) { currentPlaceID = pending }
            } else if currentPlaceID == nil || !ids.contains(currentPlaceID!) {
                currentPlaceID = ids.first
            }
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutUsView()
        }
    }
    
    // MARK: Header
    
    @State private var isShowingAbout = false

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BASYO")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(3.5)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    isShowingAbout = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.gray)
                        .frame(width: 54, height: 54)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, -12)                // 讓圖示視覺上對齊右邊界
                .accessibilityLabel("設定と情報")
            }
            .frame(height: 20)

            Text("Where are you?")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 32)
    }

    // MARK: Featured

    /// 大きなカードを横に並べたページ送り。
    ///
    /// - `.scrollTargetLayout()` と `.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))`:
    ///   指を離すとカードの位置にぴたりと止まり、どれだけ強く弾いても1枚ずつしか進まない
    /// - `.scrollPosition(id:)`: いまどのカードが表示されているかを currentPlaceID と連動させる。
    ///   逆に currentPlaceID を書き換えると、そのカードまでスクロールする
    private var featuredPager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(places) { place in
                    Button {
                        enter(place)
                    } label: {
                        FeaturedPlaceCard(place: place)
                    }
                    .buttonStyle(GatewayButtonStyle())
                    // このカードを、ズーム遷移の「出発点」として登録する。
                    .matchedTransitionSource(id: place.id, in: zoomNamespace) { source in
                        source.clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .contextMenu { menu(for: place) }
                    // カード1枚の幅を、画面の幅（左右の余白を除く）にそろえる。
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $currentPlaceID)
        .scrollIndicators(.hidden)
        // 左端は見出しや下の一覧とそろえ、右側だけ余白を広げる。
        // こうすると右隣のカードが少しのぞいて、「横にまだある」ことが分かります。
        .contentMargins(.leading, 20, for: .scrollContent)
        .contentMargins(.trailing, 32, for: .scrollContent)
        // カードの高さは画面の高さに合わせる。小さい iPhone では低く、大きい iPhone では高くなります。
        .containerRelativeFrame(.vertical) { height, _ in
            min(max(height * 0.4, 240), 380)
        }
        .sensoryFeedback(.selection, trigger: currentPlaceID)
    }

    /// 何番目の場所を表示しているかを示す点。
    private var pageDots: some View {
        HStack(spacing: 6) {
            if places.count > 1 {
                ForEach(places) { place in
                    Circle()
                        .fill(place.id == currentPlaceID ? Color.primary : Color.primary.opacity(0.18))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPlaceID)
        .frame(maxWidth: .infinity)
        .frame(height: 6)
        .padding(.top, 16)
        .padding(.bottom, 22)
    }

    // MARK: Add

    private var addPlaceButton: some View {
        Button {
            if canAddPlace {
                isAddingPlace = true
            } else {
                isShowingPaywall = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                Text("新しい場所")
                    .font(.system(size: 14))

                // 無料の上限に達しているときだけ、小さく「PRO」と添える。
                if !canAddPlace {
                    Text("PRO")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.5)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(Capsule().stroke(Color.primary.opacity(0.25), lineWidth: 1))
                }
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(GatewayButtonStyle())
    }

    // MARK: Menu

    /// 長押しメニュー。並び替えと削除。
    @ViewBuilder
    private func menu(for place: Place) -> some View {
        let index = places.firstIndex(of: place) ?? 0

        if index > 0 {
            Button {
                move(place, by: -1)
            } label: {
                Label("前へ移動", systemImage: "arrow.up")
            }
        }
        if index < places.count - 1 {
            Button {
                move(place, by: 1)
            } label: {
                Label("後ろへ移動", systemImage: "arrow.down")
            }
        }
        Button(role: .destructive) {
            placePendingDeletion = place
        } label: {
            Label("場所を削除", systemImage: "trash")
        }
    }

    // MARK: Actions

    private func select(_ place: Place) {
        withAnimation(.snappy(duration: 0.4)) {
            currentPlaceID = place.id
        }
    }

    private func enter(_ place: Place) {
        lastOpenedPlaceID = place.id.uuidString
        enteredPlace = place
    }

    /// 起動時、最後に入った場所を大きなカードに出す。見つからなければ先頭の場所。
    private func restoreSelection() {
        guard currentPlaceID == nil else { return }
        let saved = places.first { $0.id.uuidString == lastOpenedPlaceID }
        currentPlaceID = (saved ?? places.first)?.id
    }

    /// 並び順を1つ前後に動かす。
    private func move(_ place: Place, by offset: Int) {
        var ordered = places
        guard let from = ordered.firstIndex(of: place) else { return }
        let to = from + offset
        guard ordered.indices.contains(to) else { return }

        ordered.swapAt(from, to)
        // 並び順を 0, 1, 2… と振り直す。削除で番号が飛んでいても、ここで整います。
        for (index, place) in ordered.enumerated() {
            place.sortIndex = index
        }
        try? modelContext.save()
    }

    private var deletionTitle: String {
        String(localized: "「\(placePendingDeletion?.displayName ?? "")」を削除しますか？")
    }

    private func deletionMessage(for place: Place) -> String {
        let rooms = place.spaces.count
        let tasks = place.openTaskCount
        guard rooms > 0 else { return String(localized: "この操作は取り消せません。") }
        return String(localized: "部屋 \(rooms) 個、やること \(tasks) 件も一緒に削除されます。この操作は取り消せません。")
    }

    private func delete(_ place: Place) {
        // 表示中の場所を消すときは、先に隣の場所へ切り替えておく。
        if place.id == currentPlaceID, let index = places.firstIndex(of: place) {
            let neighbor = places.indices.contains(index + 1) ? places[index + 1]
                : (index > 0 ? places[index - 1] : nil)
            currentPlaceID = neighbor?.id
        }
        withAnimation(.snappy(duration: 0.35)) {
            // Place を消すと、中の Space と Task も一緒に消えます（モデルの .cascade 設定）。
            modelContext.delete(place)
            try? modelContext.save()
        }
    }
}

// MARK: - Cards

/// 大きなカード。以前の「入口」と同じ見た目で、中に入れる場所であることを示します。
private struct FeaturedPlaceCard: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: place.symbolName)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 20)

            Text(place.displayName)
                .font(.system(size: 28, weight: .regular))
                .tracking(5)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(PlaceStatus.text(for: place))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.tertiary)
                .padding(.top, 7)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    // 下にいくほどわずかに明るい面。開いたドアから光が漏れているようなニュアンス。
                    LinearGradient(
                        colors: [Color.primary.opacity(0.03), Color.primary.opacity(0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

/// 残りの場所を並べる、小さなカード。タップすると上の大きなカードがこの場所に切り替わります。
private struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: place.symbolName)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(place.displayName)
                .font(.system(size: 14, weight: .regular))
                .tracking(3)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(PlaceStatus.text(for: place))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

/// 場所の状態を表す一言。タスク数は主役ではない補助情報として、控えめに出します。
private enum PlaceStatus {
    static func text(for place: Place) -> String {
        if place.spaces.isEmpty { return String(localized: "部屋はまだありません") }
        return place.openTaskCount == 0
            ? String(localized: "すべて片付いています")
            : String(localized: "やること \(place.openTaskCount)")
    }
}

// MARK: - Interaction

/// 押した瞬間だけ、ほんの少し奥に沈む。
/// ButtonStyle にしておくと、押下状態 (isPressed) を SwiftUI 側が管理してくれます。
private struct GatewayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        PlaceHomeView()
    }
    .modelContainer(.preview)
    .environment(ProAccess())
}
