import SwiftUI
import SwiftData

/// 画面1: Place Home
///
/// リストではなく「入口が3つ並んでいる」ように見せたいので、
/// 各 Place は行ではなく、画面の高さを等分する大きな面として置いています。
struct PlaceHomeView: View {
    /// データベースから Place を読み、sortIndex 順に並べる。
    /// @Query はデータが変わると自動で読み直してくれます。
    @Query(sort: \Place.sortIndex) private var places: [Place]

    /// ズーム遷移で「押した入口」と「開く画面」を結びつけるための名前空間。
    @Namespace private var zoomNamespace

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(alignment: .leading, spacing: 0) {
                header

                // spacing を詰めすぎないことで「別々の場所」に見せています。
                VStack(spacing: 14) {
                    ForEach(places) { place in
                        NavigationLink(value: place) {
                            PlaceGateway(place: place)
                        }
                        .buttonStyle(GatewayButtonStyle())
                        // この入口を、ズーム遷移の「出発点」として登録する。
                        .matchedTransitionSource(id: place.id, in: zoomNamespace) { source in
                            source.clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        // この画面は独自の見出しを持つので、ナビゲーションバーは隠す。
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Place.self) { place in
            SpatialView(place: place)
                // 押した入口がそのまま広がって、Spatial View になる。
                .navigationTransition(.zoom(sourceID: place.id, in: zoomNamespace))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BASYO")
                .font(.system(size: 11, weight: .medium))
                .tracking(3.5)
                .foregroundStyle(.tertiary)

            Text("Where are you?")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 32)
    }
}

// MARK: - Gateway

/// ひとつの Place を表す「入口」。
/// 行ではなく面にすることで、タップが「開く」動作に感じられるようにしています。
private struct PlaceGateway: View {
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

            // 名前を下端に寄せることで、視線が下から奥へ抜けるようにしています。
            Spacer(minLength: 20)

            Text(place.name)
                .font(.system(size: 28, weight: .regular))
                .tracking(5)
                .foregroundStyle(.primary)

            Text(statusText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.tertiary)
                .padding(.top, 7)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(surface)
    }

    /// タスク数は「主役ではない補助情報」。名前の 1/2 以下のサイズで、色も最も淡い階層に置いています。
    private var statusText: String {
        place.openTaskCount == 0
            ? "すべて片付いています"
            : "やること \(place.openTaskCount)"
    }

    /// 下にいくほどわずかに明るい面。開いたドアから光が漏れているようなニュアンス。
    private var surface: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
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
}
