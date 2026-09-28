import SwiftUI
import SwiftData
import UIKit

/// 部屋の追加。
///
/// Add Task と同じく「今見ている場所に足す」。
/// どの Place に足すかは開いた時点で決まっているので、選ぶのは名前・アイコン・置く場所と大きさです。
/// 置く場所と大きさは、家の枠の中の点のマス目の上で、部屋を動かしたり広げたりして決めます。
struct AddRoomView: View {
    let place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var symbolName = RoomIcons.all[0]

    /// 新しい部屋の位置と大きさ（単位はマス）。
    @State private var rect: GridRect

    @FocusState private var isNameFocused: Bool

    init(place: Place) {
        self.place = place

        // 最初は、上から見て最初に入る空きに、以前の「小」と同じ大きさで置いておく。
        var taken: [GridRect] = []
        for space in place.spaces {
            if let existing = space.gridRect {
                taken.append(existing)
            }
        }
        let firstRect = FloorGrid.firstFreeRect(
            width: RoomSize.small.defaultGridWidth,
            height: RoomSize.small.defaultGridHeight,
            among: taken
        )
        _rect = State(initialValue: firstRect)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var others: [PlacedRoom] {
        PlacedRoom.rooms(in: place)
    }

    /// 家の枠に収まっているか（重なった部屋は押し出すので、重なりは見ない）。
    private var canPlace: Bool {
        FloorGrid.isInBounds(rect)
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty && canPlace
    }

    /// 編集画面の部屋に出す名前。まだ何も入力していなければ仮の名前。
    private var previewName: String {
        trimmedName.isEmpty ? String(localized: "新しい部屋") : trimmedName
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(place.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.tertiary)

                    TextField("部屋の名前", text: $name)
                        .font(.system(size: 22, weight: .light))
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .padding(.top, 22)

                    sectionLabel("アイコン")
                    iconPicker

                    sectionLabel("配置と大きさ")
                    RoomLayoutEditor(
                        others: others,
                        rect: $rect,
                        name: previewName,
                        symbolName: symbolName
                    )
                }
                .padding(28)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)

            actions
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
        }
        // 点のマス目を広く見せたいので、シートは画面いっぱいまで広げる。
        .presentationDetents([.large])
        // Add Task と同じく、奥が透けない不透明な背景にする。
        .presentationBackground(Color(uiColor: .systemBackground))
        // 下にスワイプして閉じようとした指が、部屋のドラッグと取り合わないように。
        .interactiveDismissDisabled()
    }

    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.top, 28)
            .padding(.bottom, 12)
    }

    // MARK: Icon

    private var iconPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(RoomIcons.all, id: \.self) { icon in
                    Button {
                        symbolName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(icon == symbolName
                                             ? Color(uiColor: .systemBackground)
                                             : Color.primary)
                            .frame(width: 46, height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(icon == symbolName ? Color.primary : Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .animation(.snappy(duration: 0.2), value: symbolName)
        .sensoryFeedback(.selection, trigger: symbolName)
    }

    // MARK: Actions

    private var actions: some View {
        HStack {
            Button("キャンセル") { dismiss() }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: add) {
                Text("部屋をつくる")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(Capsule().fill(Color.primary.opacity(canCreate ? 1 : 0.15)))
            }
            .buttonStyle(.plain)
            .disabled(!canCreate)
            .animation(.easeOut(duration: 0.15), value: canCreate)
        }
    }

    private func add() {
        guard canCreate else { return }

        let nextIndex = (place.spaces.map(\.sortIndex).max() ?? -1) + 1
        let space = Space(
            name: trimmedName,
            symbolName: symbolName,
            size: RoomSize.approximating(width: rect.width, height: rect.height),
            sortIndex: nextIndex
        )
        // ユーザーが決めた位置と大きさ。
        space.setGridRect(rect)

        // 重なっていた部屋を、押し出した先へ動かす（新しい部屋を足す前に、今ある部屋だけで計算）。
        let arranged = PlacedRoom.makingRoom(for: rect, in: others)

        // 先にデータベースへ入れてから、Place と結びつける（SwiftData の安全な順番）。
        modelContext.insert(space)
        withAnimation(.snappy(duration: 0.35)) {
            PlacedRoom.apply(arranged, to: place)
            space.place = place
        }
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Icons

/// 部屋に付けられるアイコン。SF Symbols は数千種類あるので、家や生活の場所でよく使うものに絞っています。
enum RoomIcons {
    static let all = [
        "door.left.hand.open",
        "bed.double",
        "sofa",
        "frying.pan",
        "fork.knife",
        "bathtub",
        "shower",
        "toilet",
        "washer",
        "tshirt",
        "books.vertical",
        "lamp.desk",
        "desktopcomputer",
        "laptopcomputer",
        "archivebox",
        "shippingbox",
        "car",
        "leaf",
        "gamecontroller",
        "person.2"
    ]
}

#Preview {
    let container = ModelContainer.preview
    let home = try! container.mainContext.fetch(
        FetchDescriptor<Place>(sortBy: [SortDescriptor(\.sortIndex)])
    ).first!

    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddRoomView(place: home)
        }
        .modelContainer(container)
}
