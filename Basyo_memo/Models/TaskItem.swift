import Foundation
import SwiftData

/// いちばん小さい単位、ひとつの「やること」。
///
/// 型名を `Task` にしていないのは、Swift の並行処理に同名の `Task` が
/// 標準で存在していて衝突するためです。
@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    /// このタスクが置かれている空間。
    var space: Space?

    init(title: String, createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = createdAt
    }

    /// このタスクが置かれている場所。
    ///
    /// Place は保存せず、Space からたどって求めます。
    /// 両方を保存すると同じ情報が2箇所にあることになり、食い違う原因になるためです。
    var place: Place? {
        space?.place
    }

    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? .now : nil
    }
}
