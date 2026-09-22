import SwiftUI
import SwiftData
import UIKit

/// 場所の追加。
///
/// 選ぶのは名前とアイコンだけです。作った場所は空っぽ（部屋が0個）で始まり、
/// 中に入ると「＋」の空きから部屋を足していけます。
struct AddPlaceView: View {
    /// 場所を作ったあとに呼ばれる。Place Home は、これを受けて新しい場所までスライドします。
    let onCreate: (Place) -> Void

    /// 並び順の最後を知るために、既存の場所を読む。
    @Query private var places: [Place]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var symbolName = PlaceIcons.all[0]

    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// アイコンを並べる格子。1行に6個ずつ、画面の幅に合わせて広がる。
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("新しい場所")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(.tertiary)

            TextField("場所の名前", text: $name)
                .font(.system(size: 22, weight: .light))
                .focused($isNameFocused)
                .submitLabel(.done)
                .padding(.top, 22)

            Text("アイコン")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 28)
                .padding(.bottom, 12)

            LazyVGrid(columns: iconColumns, spacing: 8) {
                ForEach(PlaceIcons.all, id: \.self) { icon in
                    Button {
                        symbolName = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(icon == symbolName
                                             ? Color(uiColor: .systemBackground)
                                             : Color.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(icon == symbolName ? Color.primary : Color.primary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.snappy(duration: 0.2), value: symbolName)
            .sensoryFeedback(.selection, trigger: symbolName)

            Spacer(minLength: 24)

            actions
        }
        .padding(28)
        .presentationDetents([.height(430)])
        // 他のシートと同じく、奥が透けない不透明な背景にする。
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    private var actions: some View {
        HStack {
            Button("キャンセル") { dismiss() }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: add) {
                Text("場所をつくる")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(Capsule().fill(Color.primary.opacity(trimmedName.isEmpty ? 0.15 : 1)))
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .animation(.easeOut(duration: 0.15), value: trimmedName.isEmpty)
        }
    }

    private func add() {
        guard !trimmedName.isEmpty else { return }

        // 並びの最後に足す。
        let nextIndex = (places.map(\.sortIndex).max() ?? -1) + 1
        let place = Place(name: trimmedName, symbolName: symbolName, sortIndex: nextIndex)
        modelContext.insert(place)
        try? modelContext.save()

        onCreate(place)
        dismiss()
    }
}

// MARK: - Icons

/// 場所に付けられるアイコン。生活の中でよく行く場所に絞っています。
enum PlaceIcons {
    static let all = [
        "house",
        "graduationcap",
        "briefcase",
        "building.2",
        "dumbbell",
        "cup.and.saucer",
        "cart",
        "bag",
        "cross.case",
        "tram",
        "car",
        "tree",
        "book.closed",
        "figure.run",
        "fork.knife",
        "bed.double",
        "heart",
        "star"
    ]
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddPlaceView { _ in }
        }
        .modelContainer(.preview)
}
