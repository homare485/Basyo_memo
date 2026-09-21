import Foundation
import SwiftData

/// いちばん外側の「場所」。HOME / UNIVERSITY / WORK。
///
/// `@Model` を付けると、SwiftData がこのクラスを保存・読み込みできる形に変換してくれます。
/// また自動で Observable にもなるので、値が変わると、この Place を表示している画面が描き直されます。
@Model
final class Place {
    var id: UUID
    var name: String
    var symbolName: String

    /// Place Home で並べる順番。
    /// SwiftData のリレーション（下の spaces）は順番を保証しないので、並び順は自分で持ちます。
    var sortIndex: Int

    /// この場所にある空間。Place を消すと、中の Space も一緒に消えます（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \Space.place)
    var spaces: [Space] = []

    init(name: String, symbolName: String, sortIndex: Int) {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.sortIndex = sortIndex
    }

    /// まだ終わっていないタスクの数。
    var openTaskCount: Int {
        spaces.reduce(0) { $0 + $1.openTaskCount }
    }
}
