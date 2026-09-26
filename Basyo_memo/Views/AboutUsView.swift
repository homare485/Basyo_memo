//
//  AboutView.swift
//  Basyo_memo
//
//  Created by Wesley on 2026/9/26.
//

import SwiftUI

/// 自己紹介に出すメンバー。
struct Member: Identifiable {
    let id = UUID()
    let photo: String                    // Assets に入れた画像の名前
    let name: String
    let role: LocalizedStringResource
    let location: LocalizedStringResource
    let bio: LocalizedStringResource
}

extension Member {
    static let all: [Member] = [
        Member(
            photo: "wesley",
            name: "Wesley Wang",
            role: "Developer · NKUST",
            location: "Taiwan",
            bio: "I'm currently pursuing my bachelor's and master's degrees through a 4+1 program, passionate about UI design and SwiftUI, and I look forward to becoming the best version of myself in the future~"
        ),
        Member(
            photo: "homare",
            name: "Homare Waki",
            role: "Developer · KU",
            location: "Japan",
            bio: "ここに自己紹介を書きます。"
        )
    ]
}

struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(Array(Member.all.enumerated()), id: \.element.id) { index, member in
                        if index > 0 { Divider() }
                        MemberSection(member: member)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("About Us")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct MemberSection: View {
    let member: Member

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 写真と名前の段
            HStack(spacing: 24) {
                Image(member.photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    Text(member.name)
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // 役割（開発・デザイン）
                    Text(member.role)
                        .font(.body)

                    Label {
                        Text(member.location)
                    } icon: {
                        Image(systemName: "location.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            // 自己紹介
            Text(member.bio)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    AboutUsView()
}
