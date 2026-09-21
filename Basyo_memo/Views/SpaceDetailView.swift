import SwiftUI
import SwiftData

/// 画面3: Space Detail
///
/// Spatial View の部屋に「入った」あとの画面。
/// 画面全体をその部屋の床として描き、タスクは床の上に置かれた物として並べます。
struct SpaceDetailView: View {
    let space: Space

    /// データベースへの書き込み口。
    @Environment(\.modelContext) private var modelContext

    /// Add Task のシートを開いているか。
    @State private var isAddingTask = false

    /// 完了した直後、消えるまでの短い間だけ表示し続けるタスク。
    /// すぐ消すと「何が起きたか」が見えないので、チェックが付いた姿を一瞬見せてから片付けます。
    @State private var lingeringIDs: Set<TaskItem.ID> = []

    /// ハプティクスを鳴らすきっかけ。値が変わるたびに1回鳴ります。
    @State private var completedCount = 0
    @State private var undoneCount = 0

    /// 画面に出すタスク = まだ終わっていないもの + 完了直後で消える途中のもの。
    /// リレーションの配列は順番が保証されないので、置いた順（createdAt）に並べ直します。
    private var visibleTasks: [TaskItem] {
        space.tasks
            .filter { !$0.isCompleted || lingeringIDs.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(alignment: .leading, spacing: 0) {
                header

                if visibleTasks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        FlowLayout(spacing: 10) {
                            ForEach(visibleTasks) { task in
                                Button {
                                    toggle(task)
                                } label: {
                                    TaskCard(task: task)
                                }
                                .buttonStyle(CardButtonStyle())
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                ))
                            }
                        }
                        .padding(.top, 36)
                        // ＋ボタンにカードが隠れないよう、下に余白を残す。
                        .padding(.bottom, 96)
                        // タスクが増えたとき、新しいカードがふわっと現れ、他のカードが滑らかに場所を譲る。
                        .animation(.snappy(duration: 0.35), value: space.tasks.count)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(floor)
            .overlay(alignment: .bottomTrailing) {
                addButton.padding(20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        // Add Task のキーボードが上がっても、奥の床や＋ボタンを押し上げない。
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: completedCount)
        .sensoryFeedback(.selection, trigger: undoneCount)
        // タスクを置いたときの、ごく軽い手応え。
        .sensoryFeedback(.impact(weight: .light), trigger: space.tasks.count)
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(space: space)
        }
    }

    // MARK: Header

    /// Spatial View の部屋と同じ並び（アイコン → 名前）にして、
    /// 「さっきの部屋が大きくなった」と感じられるようにしています。
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: space.symbolName)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.secondary)

            Text(space.name.uppercased())
                .font(.system(size: 28, weight: .regular))
                .tracking(5)
                .padding(.top, 14)

            Text(space.openTaskCount == 0 ? "片付いています" : "やること \(space.openTaskCount)")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                // 数字が変わるとき、パッと切り替わらずに数字だけが滑らかに入れ替わる。
                .contentTransition(.numericText())
                .padding(.top, 10)
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .light))
            Text("この空間は片付いています")
                .font(.system(size: 13))
        }
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    // MARK: Floor

    /// 部屋の床と壁。Spatial View の外壁と同じ線の太さ・濃さにしています。
    private var floor: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.025))
            .overlay(
                Rectangle().strokeBorder(Color.primary.opacity(0.5), lineWidth: 1.5)
            )
    }

    // MARK: Add

    private var addButton: some View {
        Button {
            isAddingTask = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .light))
                // .background は「いまの背景色」。ライトなら白、ダークなら黒になります。
                .foregroundStyle(.background)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.primary))
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityLabel("タスクを追加")
    }

    // MARK: Actions

    private func toggle(_ task: TaskItem) {
        let willComplete = !task.isCompleted

        withAnimation(.snappy(duration: 0.3)) {
            task.toggleCompletion()
            if willComplete {
                lingeringIDs.insert(task.id)
            } else {
                // 消える前にもう一度タップしたら、元に戻す。
                lingeringIDs.remove(task.id)
            }
        }

        // すぐに保存する。アプリがこの直後に終了されても、完了状態が残るように。
        try? modelContext.save()

        if willComplete {
            completedCount += 1
            // チェックの付いた姿を少し見せてから、床の上から片付ける。
            // （`Task { }` は Swift の並行処理。モデル名を TaskItem にした理由がこれです）
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeInOut(duration: 0.4)) {
                    _ = lingeringIDs.remove(task.id)
                }
            }
        } else {
            undoneCount += 1
        }
    }
}

// MARK: - Task Card

/// 床に置かれたタスク。チェックボックスの行ではなく、ひとつの「物」として見せます。
private struct TaskCard: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
                    .opacity(task.isCompleted ? 0 : 1)

                Circle()
                    .fill(Color.primary)
                    // 完了すると、中心から小さく膨らむように塗りが広がる。
                    .scaleEffect(task.isCompleted ? 1 : 0.3)
                    .opacity(task.isCompleted ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.background)
                    .opacity(task.isCompleted ? 1 : 0)
            }
            .frame(width: 18, height: 18)

            Text(task.title)
                .font(.system(size: 15))
                .foregroundStyle(task.isCompleted ? .tertiary : .primary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Flow Layout

/// 横に並べて、はみ出したら次の行へ折り返すレイアウト。
///
/// 縦一列に並べるとただのリストに見えてしまうので、
/// 長さの違うカードが床に散らばっているように見せるために使っています。
///
/// SwiftUI の `Layout` プロトコルを使うと、HStack / VStack のような並べ方を自分で定義できます。
/// やることは2つだけです:
/// - sizeThatFits: 全体でどれだけの大きさが必要かを答える
/// - placeSubviews: 子ビューを1つずつ、どこに置くか決める
private struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let frames = arrange(subviews, in: width)
        let height = frames.map(\.maxY).max() ?? 0
        return CGSize(width: proposal.width ?? frames.map(\.maxX).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(subviews, in: bounds.width)
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    /// 左上から順に置いていき、幅が足りなくなったら次の行へ。
    private func arrange(_ subviews: Subviews, in width: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            // 1枚のカードが画面幅を超えないよう、幅の上限を渡して大きさを聞く。
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))

            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return frames
    }
}

#Preview {
    let container = ModelContainer.preview
    let kitchen = try! container.mainContext.fetch(
        FetchDescriptor<Space>(predicate: #Predicate { $0.name == "Kitchen" })
    ).first!

    NavigationStack {
        SpaceDetailView(space: kitchen)
    }
    .modelContainer(container)
}
