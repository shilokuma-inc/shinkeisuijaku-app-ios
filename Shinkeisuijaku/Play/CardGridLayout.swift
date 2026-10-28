//
//  CardGridLayout.swift
//  Shinkeisuijaku
//
//  プレイ画面のカードの並べ方（引き継ぎブックの「カードの並び」）。4 列で、行は使える高さで等分する（iPhone SE の 10 ペアでもスクロールしない）。
//  ただし、カードの高さは幅の `Metrics.cardMaxAspectRatio` 倍までにして、縦に長くなりすぎないようにする（あまった高さは呼び出し側が上下に分ける）。
//  View から切り離した値の型にして、単体テストする。
//

import CoreGraphics

/// カードの並べ方
struct CardGridLayout: Equatable {
    /// 列の数
    let columns: Int
    /// 行の数
    let rows: Int
    /// 1 枚のカードの大きさ
    let cardSize: CGSize

    /// - Parameters:
    ///   - cardCount: カードの枚数
    ///   - available: カードを並べられる大きさ（左右の余白・上と下の表示を除いたもの）
    init(cardCount: Int, available: CGSize) {
        let columns = Metrics.cardColumns
        let rows = max((cardCount + columns - 1) / columns, 1)
        let spacing = Metrics.cardSpacing
        // 文字を大きくして使える高さが減っても、負の大きさにしない
        let width = max((available.width - spacing * CGFloat(columns - 1)) / CGFloat(columns), 0)
        let evenHeight = max((available.height - spacing * CGFloat(rows - 1)) / CGFloat(rows), 0)
        self.columns = columns
        self.rows = rows
        cardSize = CGSize(width: width, height: min(evenHeight, width * Metrics.cardMaxAspectRatio))
    }
}
