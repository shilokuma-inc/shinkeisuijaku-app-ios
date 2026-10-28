//
//  StampBookView.swift
//  Shinkeisuijaku
//
//  スタンプちょうの画面（引き継ぎブックの 10 ページ・仕様書の「スタンプ」）。見出し・集めた数（「5 / 12」）・通常の 12 枠（4 列 × 3 段）・
//  パス専用の 4 枠（銀と金の 2 段）と、下に「ホームにもどる」。期限・連続日数・ランキングは出さない。
//  どの枠に何を出すかは `StampBookLayout` が決め、この画面はそれを並べるだけ。
//

import SwiftUI

/// スタンプちょうの画面
struct StampBookView: View {
    let layout: StampBookLayout
    /// 「ホームにもどる」を押したとき
    var onHome: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            let diameter = StampBookLayout.diameter(forWidth: proxy.size.width - Metrics.screenHorizontalPadding * 2)
            // 画面に入らないとき（iPhone SE で文字を大きくしたときなど）は、スクロールで全部見られる
            ScrollView {
                content(diameter: diameter)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // 「ホームにもどる」はスクロールしても隠れないよう、下に固定する
        .safeAreaInset(edge: .bottom, spacing: 0) {
            homeButton
        }
        .background(Palette.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stampBook")
    }

    /// 見出し・集めた数・通常の枠・パス専用の枠（上から順に並べる）
    private func content(diameter: CGFloat) -> some View {
        VStack(spacing: Metrics.stampBookSectionSpacing) {
            Text("スタンプちょう")
                .appFont(Typography.dialogTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            countBadge
            stampRows(layout.regularRows, columns: StampBookLayout.regularColumns, diameter: diameter, identifier: "stampBook.regular")
            VStack(spacing: Metrics.stampBookSpacing) {
                Text("とくべつな スタンプ")
                    .appFont(Typography.noteStrong)
                    .foregroundStyle(Palette.muted)
                    .accessibilityAddTraits(.isHeader)
                stampRows(layout.passRows, columns: StampBookLayout.passColumns, diameter: diameter, identifier: "stampBook.pass")
            }
        }
        .padding(.horizontal, Metrics.screenHorizontalPadding)
        .padding(.vertical, Metrics.cardSpacing)
    }

    /// 集めた数（「あつめた かず 5 / 12」。「あと◯ペア」と同じ形の札にし、数字は強調色で大きく）
    private var countBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.cardSpacing) {
            Text("あつめた かず")
                .appFont(Typography.pairCountLabel)
                .foregroundStyle(Palette.text)
            Text("\(layout.collectedCount) / \(layout.totalCount)")
                .appFont(Typography.pairCountNumber)
                .foregroundStyle(Palette.accent)
        }
        .lineLimit(1)
        .padding(.vertical, Metrics.pairCountVerticalPadding)
        .padding(.horizontal, Metrics.pairCountHorizontalPadding)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius)
                .stroke(Palette.border, lineWidth: Metrics.borderWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: layout.countAccessibilityLabel))
        .accessibilityIdentifier("stampBook.count")
    }

    /// 枠を段ごとに並べる。識別子の番号は、上の段の左から数える
    private func stampRows(
        _ rows: [[StampBookLayout.Entry]],
        columns: Int,
        diameter: CGFloat,
        identifier: String
    ) -> some View {
        VStack(spacing: Metrics.stampBookSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: Metrics.stampBookSpacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, entry in
                        StampView(slot: entry.slot, diameter: diameter)
                            // 部品は読み上げを持たないので、枠の状態を言葉で付ける
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(verbatim: StampBookLayout.accessibilityLabel(for: entry)))
                            .accessibilityIdentifier("\(identifier).\(rowIndex * columns + columnIndex)")
                    }
                }
            }
        }
    }

    /// 「ホームにもどる」（仕様書の遷移先はホームだけなので、戻るボタンではなく言葉のボタンにする）
    private var homeButton: some View {
        Button(action: onHome) {
            Text("ホームにもどる")
                .appFont(Typography.button)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        .accessibilityIdentifier("stampBook.home")
        .padding(.horizontal, Metrics.screenHorizontalPadding)
        .padding(.vertical, Metrics.cardSpacing)
        .background(Palette.background)
    }
}

/// 撮影モードのスタンプちょう。通常を 5 つとパス専用（どうぶつ・ふつう）を 1 つ集めた、パスを買った後の状態で開く（保存は使わない）
struct StampBookScreenshotDemoView: View {
    private static let owned: [Stamp] = [
        .regular(.cat), .regular(.rabbit), .regular(.panda), .regular(.chick), .regular(.apple), .pass(.animals, .silver)
    ]

    var body: some View {
        StampBookView(layout: StampBookLayout(owned: StampCollection(ids: Self.owned.map(\.id)), hasPass: true))
    }
}

#Preview("パスを買った後") {
    StampBookScreenshotDemoView()
}

#Preview("パスを買う前") {
    StampBookView(layout: StampBookLayout(owned: StampCollection(ids: [Stamp.regular(.dog).id]), hasPass: false))
}
