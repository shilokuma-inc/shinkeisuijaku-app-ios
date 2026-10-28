//
//  PlayScreenTests.swift
//  ShinkeisuijakuTests
//
//  プレイ画面のヒントのボタンを押せる見た目にするかを確かめる（ハズレのあいだにちらつかない）。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct PlayScreenTests {
    /// めくれるあいだと、短く待つあいだ（ハズレを戻す・ヒント）は、ヒントのボタンを薄くしない
    @Test
    func hintStaysEnabledDuringShortWaits() {
        #expect(PlayScreen.hintLooksEnabled(phase: .playing))
        #expect(PlayScreen.hintLooksEnabled(phase: .resolvingMismatch))
        #expect(PlayScreen.hintLooksEnabled(phase: .hinting))
    }

    /// 始めに全部見せているあいだ・クリアを待つあいだ・クリアの後・やめた後は、薄くする
    @Test
    func hintLooksDisabledWhileUnavailableForLong() {
        for phase: GameSession.Phase in [.ready, .revealingAll, .finishing, .cleared, .quit] {
            #expect(!PlayScreen.hintLooksEnabled(phase: phase), "\(phase)")
        }
    }

    /// ハズレのあいだにヒントを押しても、ヒントは始まらない（見た目は押せても、ゲームの規則では押せない）
    @Test
    func hintTappedDuringMismatchIsIgnored() async throws {
        var generator = SeededRandomNumberGenerator(seed: 3)
        let session = GameSession(
            course: .animals,
            difficulty: .easy,
            isBeforeFirstClear: false,
            timing: .standard,
            clock: InstantGameClock(),
            using: &generator
        )
        session.start()
        await session.waitForPendingWork()
        let cards = session.board.cards
        let first = try #require(cards.first)
        let other = try #require(cards.first { $0.pairID != first.pairID })
        session.flip(cardID: first.id)
        #expect(session.flip(cardID: other.id) == .mismatched)
        #expect(PlayScreen.hintLooksEnabled(phase: session.phase))
        session.showHint()
        #expect(session.phase == .resolvingMismatch)
    }
}
