import SwiftUI
import SwiftData
import UIKit

/// 画面4: Add Task
///
/// 「どこに置きますか？」とは聞かない。
/// 今見ている Space に、そのまま置く。入力するのはタイトルだけです。
struct AddTaskView: View {
    /// タスクを置く先。開いた時点で決まっているので、ユーザーには選ばせません。
    let space: Space

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    /// キーボードのフォーカス。true にすると入力欄にカーソルが入り、キーボードが上がります。
    @FocusState private var isFocused: Bool

    /// 前後の空白を除いたタイトル。空白だけのタスクは置けないようにします。
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            location

            TextField("やることを入力", text: $title)
                .font(.system(size: 22, weight: .light))
                .focused($isFocused)
                // キーボードの改行キーを「完了」にして、押したらそのまま置く。
                .submitLabel(.done)
                .onSubmit(add)
                .padding(.top, 22)

            Spacer(minLength: 24)

            actions
        }
        .padding(28)
        // 画面を覆い尽くさず、キーボードのすぐ上に収まる高さ。
        .presentationDetents([.height(230)])
        // iOS 26 の高さ指定シートは標準でガラス（半透明）になり、奥のカードが透けて見えます。
        // 入力に集中できるよう、不透明な背景にしています。
        .presentationBackground(Color(uiColor: .systemBackground))
        .onAppear { isFocused = true }
    }

    // MARK: Location

    /// 現在地。「どこに置くか」を聞く代わりに、「ここに置く」と静かに示すだけにします。
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

    // MARK: Actions

    private var actions: some View {
        HStack {
            Button("キャンセル") { dismiss() }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: add) {
                // 「追加」ではなく「置く」。このアプリの考え方をボタンの言葉にしています。
                Text("\(space.name.uppercased()) に置く")
                    .font(.system(size: 15, weight: .medium))
                    // 文字色は「画面の背景色」を明示的に使う（ライトなら白、ダークなら黒）。
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    // 空のときは、ボタン自体を薄くして「まだ置けない」ことを示す。
                    .background(Capsule().fill(Color.primary.opacity(trimmedTitle.isEmpty ? 0.15 : 1)))
            }
            // システム標準の押下・無効時の装飾を切り、見た目を上の指定だけで決める。
            .buttonStyle(.plain)
            .disabled(trimmedTitle.isEmpty)
            .animation(.easeOut(duration: 0.15), value: trimmedTitle.isEmpty)
        }
    }

    private func add() {
        guard !trimmedTitle.isEmpty else { return }

        let task = TaskItem(title: trimmedTitle)
        // 先にデータベースへ入れてから、Space と結びつける（SwiftData の安全な順番）。
        modelContext.insert(task)
        task.space = space
        // すぐに保存する。アプリがこの直後に終了されても、タスクが残るように。
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
            AddTaskView(space: kitchen)
        }
        .modelContainer(container)
}
