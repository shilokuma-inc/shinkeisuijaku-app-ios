//
//  CardGridLayoutTests.swift
//  ShinkeisuijakuTests
//
//  プレイ画面のカードの並べ方（4 列・行は高さで等分・縦横比の上限）を、iPhone SE と iPad の大きさで確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct CardGridLayoutTests {
    /// iPhone SE（第 3 世代）で、カードを並べられるおよその大きさ（幅 375 から左右の余白 10 を除き、
    /// 高さ 667 からステータスバー・上下の余白・「あと◯ペア」と説明の 1 行・ヒントとやめるを除いたもの）
    private static let iPhoneSEArea = CGSize(width: 355, height: 490)
    /// iPad Pro 13-inch の縦で、中身の幅の上限（600）から左右の余白を除いた大きさ
    private static let iPadArea = CGSize(width: Metrics.contentMaxWidth - Metrics.gameHorizontalPadding * 2, height: 1180)

    /// 並べたときの高さ（すき間を含む）
    private func totalHeight(_ layout: CardGridLayout) -> CGFloat {
        layout.cardSize.height * CGFloat(layout.rows) + Metrics.cardSpacing * CGFloat(layout.rows - 1)
    }

    /// 並べたときの幅（すき間を含む）
    private func totalWidth(_ layout: CardGridLayout) -> CGFloat {
        layout.cardSize.width * CGFloat(layout.columns) + Metrics.cardSpacing * CGFloat(layout.columns - 1)
    }

    /// 6・8・10 ペアは 4 列で、行は 3・4・5 段
    @Test(arguments: [(Difficulty.easy, 3), (.normal, 4), (.hard, 5)])
    func fourColumnsAndRowsPerDifficulty(difficulty: Difficulty, rows: Int) {
        let layout = CardGridLayout(cardCount: difficulty.pairCount * 2, available: Self.iPhoneSEArea)
        #expect(layout.columns == 4)
        #expect(layout.rows == rows)
    }

    /// iPhone SE の 10 ペア（5 段）は、行を高さで等分してスクロールせずに収まり、カードは押せる大きさ（44 以上）を保つ
    @Test
    func hardFitsOnIPhoneSEWithoutScrolling() {
        let layout = CardGridLayout(cardCount: Difficulty.hard.pairCount * 2, available: Self.iPhoneSEArea)
        #expect(totalHeight(layout) <= Self.iPhoneSEArea.height)
        #expect(totalWidth(layout) <= Self.iPhoneSEArea.width)
        // 縦横比の上限に届かないので、高さで等分したまま: (490 - 8 × 4) / 5
        #expect(layout.cardSize.height == (Self.iPhoneSEArea.height - Metrics.cardSpacing * 4) / 5)
        #expect(layout.cardSize.width >= Metrics.minTapTarget)
        #expect(layout.cardSize.height >= Metrics.minTapTarget)
    }

    /// 高さが余るとき（iPad・6 ペア）は、カードの高さを幅の上限の割合までにする（縦に長くなりすぎない）
    @Test
    func cardHeightIsCappedByAspectRatio() {
        let layout = CardGridLayout(cardCount: Difficulty.easy.pairCount * 2, available: Self.iPadArea)
        // (580 - 8 × 3) / 4 = 139
        #expect(layout.cardSize.width == 139)
        #expect(layout.cardSize.height == 139 * Metrics.cardMaxAspectRatio)
        #expect(totalHeight(layout) < Self.iPadArea.height)
    }

    /// どの難易度でも、カードは幅の上限の割合より縦に長くならない
    @Test(arguments: Difficulty.allCases)
    func aspectRatioNeverExceedsLimit(difficulty: Difficulty) {
        for area in [Self.iPhoneSEArea, Self.iPadArea] {
            let layout = CardGridLayout(cardCount: difficulty.pairCount * 2, available: area)
            #expect(layout.cardSize.height <= layout.cardSize.width * Metrics.cardMaxAspectRatio)
        }
    }

    /// 文字を大きくして使える大きさが無くなっても、負の大きさにしない
    @Test
    func zeroAreaGivesZeroSize() {
        let layout = CardGridLayout(cardCount: 20, available: .zero)
        #expect(layout.cardSize == .zero)
    }
}
