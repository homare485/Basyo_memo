import SwiftUI
import SwiftData
import UIKit

/// 部屋の追加。
///
/// Add Task と同じく「今見ている場所に足す」。
/// どの Place に足すかは開いた時点で決まっているので、選ぶのは名前・大きさ・アイコンだけです。
struct AddRoomView: View {
    let place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var size: RoomSize = .small
    @State private var symbolName = RoomIcons.all[0]

    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
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

            sectionLabel("大きさ")
            sizePicker

            sectionLabel("アイコン")
            iconPicker

            Spacer(minLength: 24)

            actions
        }
        .padding(28)
        .presentationDetents([.height(470)])
        // Add Task と同じく、奥が透けない不透明な背景にする。
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.top, 28)
            .padding(.bottom, 12)
    }

    // MARK: Size

    /// 大きさの選択。文字だけでなく、間取りの上で使うマスを小さな図で見せます。
    private var sizePicker: some View {
        HStack(spacing: 10) {
            ForEach(RoomSize.allCases, id: \.self) { option in
                Button {
                    size = option
                } label: {
                    VStack(spacing: 10) {
                        SizeDiagram(size: option)
                        Text(option.label)
                            .font(.system(size: 13))
                            .foregroundStyle(option == size ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.primary.opacity(option == size ? 0.06 : 0.02))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(option == size ? 0.6 : 0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("大きさ \(option.label)")
                .accessibilityAddTraits(option == size ? .isSelected : [])
            }
        }
        .animation(.snappy(duration: 0.2), value: size)
        .sensoryFeedback(.selection, trigger: size)
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
                    .background(Capsule().fill(Color.primary.opacity(trimmedName.isEmpty ? 0.15 : 1)))
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .animation(.easeOut(duration: 0.15), value: trimmedName.isEmpty)
        }
    }

    private func add() {
        guard !trimmedName.isEmpty else { return }

        // 最後に足した部屋の、次の順番にする。間取りでは、上から見て最初に入る空きに置かれます。
        let nextIndex = (place.spaces.map(\.sortIndex).max() ?? -1) + 1
        let space = Space(name: trimmedName, symbolName: symbolName, size: size, sortIndex: nextIndex)

        // 先にデータベースへ入れてから、Place と結びつける（SwiftData の安全な順番）。
        modelContext.insert(space)
        withAnimation(.snappy(duration: 0.35)) {
            space.place = place
        }
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Size Diagram

/// 2×2 のマス目のうち、その大きさの部屋が使うマスだけを塗った小さな図。
private struct SizeDiagram: View {
    let size: RoomSize

    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(0..<2, id: \.self) { row in
                GridRow {
                    ForEach(0..<2, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.primary.opacity(isUsed(row: row, column: column) ? 0.8 : 0.1))
                            .frame(width: 13, height: 13)
                    }
                }
            }
        }
    }

    private func isUsed(row: Int, column: Int) -> Bool {
        row < size.rows && column < size.columns
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
