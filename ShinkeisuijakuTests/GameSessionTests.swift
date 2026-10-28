//
//  GameSessionTests.swift
//  ShinkeisuijakuTests
//
//  ゲームの進み方（全部見せる・ハズレを戻す・ヒント・クリア）を、実際の時間を待たずに確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

/// 待った秒数を記録して、すぐに戻る時計
@MainActor
final class ImmediateClock: GameClock {
    private(set) var requested: [TimeInterval] = []

    func sleep(for seconds: TimeInterval) async {
        requested.append(seconds)
    }
}

/// `sleep` で止まり、`advance()` を呼ぶまで進まない時計。待っているあいだの状態を確かめるために使う
@MainActor
final class GatedClock: GameClock {
    private(set) var requested: [TimeInterval] = []
    private var sleepers: [CheckedContinuation<Void, Never>] = []
    private var watchers: [CheckedContinuation<Void, Never>] = []

    func sleep(for seconds: TimeInterval) async {
        requested.append(seconds)
        await withCheckedContinuation { continuation in
            sleepers.append(continuation)
            let waiting = watchers
            watchers = []
            waiting.forEach { $0.resume() }
        }
    }

    /// だれかが `sleep` で止まるまで待つ
    func waitUntilSleeping() async {
        guard sleepers.isEmpty else {
            return
        }
        await withCheckedContinuation { watchers.append($0) }
    }

    /// 止まっている `sleep` をすべて進める
    func advance() {
        let waking = sleepers
        sleepers = []
        waking.forEach { $0.resume() }
    }
}

struct GameSessionTests {
    /// テスト用の秒数。どの待ち時間かを見分けられるよう、すべて違う値にする
    private let timing = GameTiming(
        revealAll: { pairCount, isBeforeFirstClear in isBeforeFirstClear ? 4.8 : Double(pairCount) },
        mismatchDelay: 0.9,
        hintDuration: 1.1,
        clearDialogDelay: 1.3
    )

    private func makeSession(
        _ course: Course = .animals,
        _ difficulty: Difficulty = .easy,
        isBeforeFirstClear: Bool = false,
        clock: any GameClock
    ) -> GameSession {
        var generator = SeededRandomNumberGenerator(seed: 7)
        let board = GameDealer.deal(course: course, difficulty: difficulty, using: &generator)
        return GameSession(
            course: course,
            difficulty: difficulty,
            isBeforeFirstClear: isBeforeFirstClear,
            board: board,
            timing: timing,
            clock: clock
        )
    }

    private func pairs(of session: GameSession) -> [[Card]] {
        Dictionary(grouping: session.board.cards, by: \.pairID).values.sorted { $0[0].pairID < $1[0].pairID }
    }

    /// アプリで使う秒数は、引き継ぎブックの「動き」の値
    @Test
    func standardTimingUsesHandoffBookValues() {
        let standard = GameTiming.standard
        #expect(standard.revealAll(6, false) == 2.6)
        #expect(standard.revealAll(8, false) == 3.0)
        #expect(standard.revealAll(10, false) == 3.4)
        #expect(standard.revealAll(6, true) == 4.8)
        #expect(standard.mismatchDelay == 0.9)
        #expect(standard.hintDuration == 1.1)
        #expect(standard.clearDialogDelay == 1.1)
    }

    // MARK: - 始めに全部見せる

    /// 始めに全部のカードを見せ、そのあいだは押せない。時間がたつとめくれるようになる
    @Test
    func startRevealsAllCardsThenAllowsPlay() async {
        let clock = GatedClock()
        let session = makeSession(.animals, .normal, clock: clock)
        #expect(session.phase == .ready)
        let starting = Task { await session.start() }
        await clock.waitUntilSleeping()
        #expect(session.phase == .revealingAll)
        #expect(session.isInputLocked)
        #expect(session.board.cards.allSatisfy { session.isShowingFace(of: $0) })
        #expect(await session.flip(cardID: 0) == .ignored)
        clock.advance()
        await starting.value
        #expect(session.phase == .playing)
        #expect(!session.isInputLocked)
        #expect(session.board.cards.allSatisfy { !session.isShowingFace(of: $0) })
        #expect(clock.requested == [8])
    }

    /// 初回クリア前のゲームは、ペアの数によらず全部見せる時間が長い
    @Test
    func startBeforeFirstClearUsesLongerReveal() async {
        let clock = ImmediateClock()
        let session = makeSession(.animals, .easy, isBeforeFirstClear: true, clock: clock)
        await session.start()
        #expect(clock.requested == [4.8])
        #expect(session.phase == .playing)
    }

    // MARK: - めくり

    /// ハズレの 2 枚は少しのあいだ見せてから裏に戻り、そのあいだはほかのカードもヒントも押せない
    @Test
    func mismatchLocksInputUntilCardsTurnBack() async {
        let clock = GatedClock()
        let gated = makeSession(clock: clock)
        let starting = Task { await gated.start() }
        await clock.waitUntilSleeping()
        clock.advance()
        await starting.value

        let all = pairs(of: gated)
        #expect(await gated.flip(cardID: all[0][0].id) == .firstCard)
        let flipping = Task { await gated.flip(cardID: all[1][0].id) }
        await clock.waitUntilSleeping()
        #expect(gated.phase == .resolvingMismatch)
        #expect(gated.isInputLocked)
        #expect(!gated.canShowHint)
        #expect(gated.board.unmatchedFaceUpCards.count == 2)
        #expect(await gated.flip(cardID: all[2][0].id) == .ignored)
        clock.advance()
        #expect(await flipping.value == .mismatched)
        #expect(gated.phase == .playing)
        #expect(gated.board.unmatchedFaceUpCards.isEmpty)
        #expect(clock.requested.last == 0.9)
    }

    /// ペアが揃うとすぐに次をめくれる（待たない）
    @Test
    func matchDoesNotWait() async {
        let clock = ImmediateClock()
        let session = makeSession(clock: clock)
        await session.start()
        let pair = pairs(of: session)[0]
        #expect(await session.flip(cardID: pair[0].id) == .firstCard)
        #expect(await session.flip(cardID: pair[1].id) == .matched)
        #expect(session.phase == .playing)
        #expect(session.remainingPairs == 5)
        #expect(clock.requested == [6])
    }

    // MARK: - ヒント

    /// ヒントは裏のカードを全部少しのあいだ見せ、何回でも使える
    @Test
    func hintShowsAllCardsAndCanRepeat() async {
        let clock = GatedClock()
        let session = makeSession(clock: clock)
        let starting = Task { await session.start() }
        await clock.waitUntilSleeping()
        clock.advance()
        await starting.value

        for _ in 0..<3 {
            let hinting = Task { await session.showHint() }
            await clock.waitUntilSleeping()
            #expect(session.phase == .hinting)
            #expect(session.board.cards.allSatisfy { session.isShowingFace(of: $0) })
            #expect(await session.flip(cardID: 0) == .ignored)
            clock.advance()
            await hinting.value
            #expect(session.phase == .playing)
            #expect(session.board.cards.allSatisfy { !session.isShowingFace(of: $0) })
        }
        #expect(clock.requested == [6, 1.1, 1.1, 1.1])
    }

    /// 始まる前と全部見せているあいだは、ヒントを押しても何も起きない
    @Test
    func hintIsIgnoredBeforePlaying() async {
        let clock = ImmediateClock()
        let session = makeSession(clock: clock)
        await session.showHint()
        #expect(session.phase == .ready)
        #expect(clock.requested.isEmpty)
    }

    // MARK: - クリア

    /// 全部揃えると、少し待ってからクリアになる
    @Test
    func matchingAllPairsClearsAfterDelay() async {
        let clock = GatedClock()
        let session = makeSession(.hiragana, .easy, clock: clock)
        let starting = Task { await session.start() }
        await clock.waitUntilSleeping()
        clock.advance()
        await starting.value

        let all = pairs(of: session)
        for pair in all.dropLast() {
            _ = await session.flip(cardID: pair[0].id)
            _ = await session.flip(cardID: pair[1].id)
        }
        let last = all[all.count - 1]
        _ = await session.flip(cardID: last[0].id)
        let finishing = Task { await session.flip(cardID: last[1].id) }
        await clock.waitUntilSleeping()
        #expect(session.phase == .finishing)
        #expect(session.remainingPairs == 0)
        #expect(session.isInputLocked)
        clock.advance()
        #expect(await finishing.value == .matched)
        #expect(session.phase == .cleared)
        #expect(clock.requested == [6, 1.3])
    }
}
