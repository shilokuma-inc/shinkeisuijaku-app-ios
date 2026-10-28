//
//  StampBookLayoutTests.swift
//  ShinkeisuijakuTests
//
//  スタンプちょうの並べ方（どの枠に何を出すか・パスの権利で鍵の有無・集めた数・読み上げ・直径）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct StampBookLayoutTests {
    private func layout(owned: [Stamp] = [], hasPass: Bool = false) -> StampBookLayout {
        StampBookLayout(owned: StampCollection(ids: owned.map(\.id)), hasPass: hasPass)
    }

    // MARK: - 枠

    /// 何も持っていないときは、通常の 12 枠がすべて「まだ」で、集めた数は「0 / 12」
    @Test
    func emptyBookShowsAllRegularSlotsAsEmpty() {
        let book = layout()
        #expect(book.regular.count == 12)
        #expect(book.regular.map(\.stamp) == Stamp.regularStamps)
        #expect(book.regular.allSatisfy { $0.slot == .empty })
        #expect(book.collectedCount == 0)
        #expect(book.totalCount == 12)
    }

    /// 通常の枠は 4 列 × 3 段で、枠の場所はスタンプごとに決まっている（もらった順に詰めない）
    @Test
    func regularSlotsKeepTheirPlaces() {
        let book = layout(owned: [.regular(.suika), .regular(.cat)])
        #expect(book.regularRows.map(\.count) == [4, 4, 4])
        #expect(book.regular[0].slot == .owned(.regular(.cat)))
        #expect(book.regular[11].slot == .owned(.regular(.suika)))
        #expect(book.regular[1...10].allSatisfy { $0.slot == .empty })
    }

    /// パス専用の枠は、1 段目が銀（どうぶつ・ひらがな）、2 段目が金（どうぶつ・ひらがな）
    @Test
    func passSlotsAreSilverThenGoldRows() {
        let book = layout(hasPass: true)
        #expect(book.passRows.map { $0.map(\.stamp) } == [
            [.pass(.animals, .silver), .pass(.hiragana, .silver)],
            [.pass(.animals, .gold), .pass(.hiragana, .gold)]
        ])
    }

    /// パスを買う前は、まだのパス専用の枠に鍵を出す
    @Test
    func passSlotsAreLockedWithoutPass() {
        let book = layout(hasPass: false)
        #expect(book.pass.count == 4)
        #expect(book.pass.allSatisfy { $0.slot == .locked })
    }

    /// パスを買った後は、まだのパス専用の枠は鍵を消して ふつうの「まだ」にし、もらったものはスタンプを出す
    @Test
    func passSlotsUnlockWithPass() {
        let book = layout(owned: [.pass(.hiragana, .gold)], hasPass: true)
        #expect(book.pass.map(\.slot) == [.empty, .empty, .empty, .owned(.pass(.hiragana, .gold))])
    }

    /// 返金などでパスの権利が無くなっても、もらったパス専用のスタンプは出し、まだの枠だけ鍵にする
    @Test
    func ownedPassStampStaysWithoutPass() {
        let book = layout(owned: [.pass(.animals, .silver)], hasPass: false)
        #expect(book.pass.map(\.slot) == [.owned(.pass(.animals, .silver)), .locked, .locked, .locked])
    }

    // MARK: - 集めた数

    /// 集めた数は通常のスタンプだけを数え、パス専用のスタンプは数に含めない
    @Test
    func collectedCountCountsRegularStampsOnly() {
        let owned: [Stamp] = [.regular(.cat), .regular(.dog), .pass(.animals, .silver), .regular(.fox), .pass(.hiragana, .gold)]
        let book = layout(owned: owned, hasPass: true)
        #expect(book.collectedCount == 3)
        #expect(book.totalCount == 12)
    }

    /// 全部そろったら「12 / 12」
    @Test
    func collectedCountWhenComplete() {
        let book = layout(owned: Stamp.regularStamps)
        #expect(book.collectedCount == 12)
        #expect(book.regular.allSatisfy { $0.slot == .owned($0.stamp) })
    }

    /// 集めた数は「スラッシュ」と読ませず、言葉で読み上げる
    @Test
    func countIsReadAsWords() {
        let book = layout(owned: Array(Stamp.regularStamps.prefix(5)))
        #expect(book.countAccessibilityLabel == "あつめた スタンプ 12 こ の うち 5 こ")
    }

    // MARK: - 読み上げ

    /// もらったスタンプは名前、まだの枠は「まだ」、鍵の枠は「かぎ」と読み上げる（パス専用の枠は、どの枠かも言う）
    @Test
    func slotLabelsDescribeTheState() {
        let book = layout(owned: [.regular(.cat), .pass(.animals, .silver)], hasPass: false)
        let label = StampBookLayout.accessibilityLabel(for:)
        #expect(label(book.regular[0]) == "ネコ")
        #expect(label(book.regular[1]) == "まだ", "まだの通常の枠は、どのスタンプかを言わない")
        #expect(label(book.pass[0]) == "どうぶつ ふつう")
        #expect(label(book.pass[1]) == "ひらがな ふつう かぎ")
        #expect(label(book.pass[3]) == "ひらがな むずかしい かぎ")
        let unlocked = layout(hasPass: true)
        #expect(label(unlocked.pass[2]) == "どうぶつ むずかしい まだ")
    }

    // MARK: - 直径

    /// 直径は幅から決め、72〜80 に収める
    @Test
    func diameterFollowsWidthWithinRange() {
        // iPhone SE（第 3 世代）の幅 375 から左右の余白 16 を除いた 343: (343 - 8 × 3) / 4 = 79.75
        #expect(StampBookLayout.diameter(forWidth: 343) == 79.75)
        // iPhone 17 Pro の幅 402: 上限の 80
        #expect(StampBookLayout.diameter(forWidth: 370) == Metrics.stampBookMaxDiameter)
        // 狭いときも下限の 72 より小さくしない
        #expect(StampBookLayout.diameter(forWidth: 200) == Metrics.stampBookMinDiameter)
        #expect(StampBookLayout.diameter(forWidth: 0) == Metrics.stampBookMinDiameter)
    }
}
