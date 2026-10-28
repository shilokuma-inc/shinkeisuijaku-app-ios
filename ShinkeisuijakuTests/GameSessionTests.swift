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

/// `sleep` で止まり、`advance()` を呼ぶか cancel されるまで進まない時計。待っているあいだの状態を確かめるために使う
@MainActor
final class GatedClock: GameClock {
    private(set) var requested: [TimeInterval] = []
    private var sleepers: [CheckedContinuation<Void, Never>] = []
    private var watchers: [CheckedContinuation<Void, Never>] = []

    func sleep(for seconds: TimeInterval) async {
        requested.append(seconds)
        // cancel されたら（`quit()` やテストの時間切れ）、進めるのを待たずに戻る
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                sleepers.append(continuation)
                let waiting = watchers
                watchers = []
                waiting.forEach { $0.resume() }
            }
        } onCancel: {
            Task { @MainActor in
                self.advance()
            }
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

/// 待ち時間で止まったまま終わらないテストを、CI のタイムアウトより先に落とす
@Suite(.timeLimit(.minutes(1)))
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
        return GameSession(
            course: course,
            difficulty: difficulty,
            isBeforeFirstClear: isBeforeFirstClear,
            timing: timing,
            clock: clock,
            using: &generator
        )
    }

    private func pairs(of session: GameSession) -> [[Card]] {
        Dictionary(grouping: session.board.cards, by: \.pairID).values.sorted { $0[0].pairID < $1[0].pairID }
    }

    /// 始めに全部見せるのを終わらせて、めくれる状態にする
    private func startPlaying(_ session: GameSession, clock: GatedClock) async {
        session.start()
        await clock.waitUntilSleeping()
        clock.advance()
        await session.waitForPendingWork()
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

    /// 難易度のペアの数だけ配ってある
    @Test
    func sessionDealsCardsForTheDifficulty() {
        let session = makeSession(.hiragana, .hard, clock: ImmediateClock())
        #expect(session.board.cards.count == 20)
        #expect(session.remainingPairs == 10)
    }

    // MARK: - 始めに全部見せる

    /// 始めに全部のカードを見せ、そのあいだは押せない。時間がたつとめくれるようになる
    @Test
    func startRevealsAllCardsThenAllowsPlay() async {
        let clock = GatedClock()
        let session = makeSession(.animals, .normal, clock: clock)
        #expect(session.phase == .ready)
        session.start()
        await clock.waitUntilSleeping()
        #expect(session.phase == .revealingAll)
        #expect(session.isInputLocked)
        #expect(session.board.cards.allSatisfy { session.isShowingFace(of: $0) })
        #expect(session.flip(cardID: 0) == .ignored)
        session.start()
        #expect(clock.requested == [8], "全部見せているあいだにもう一度 start しても、待ち直さない")
        clock.advance()
        await session.waitForPendingWork()
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
        session.start()
        await session.waitForPendingWork()
        #expect(clock.requested == [4.8])
        #expect(session.phase == .playing)
    }

    // MARK: - めくり

    /// ハズレの 2 枚は少しのあいだ見せてから裏に戻り、そのあいだはほかのカードもヒントも押せない
    @Test
    func mismatchLocksInputUntilCardsTurnBack() async {
        let clock = GatedClock()
        let session = makeSession(clock: clock)
        await startPlaying(session, clock: clock)

        let all = pairs(of: session)
        #expect(session.flip(cardID: all[0][0].id) == .firstCard)
        #expect(session.flip(cardID: all[1][0].id) == .mismatched, "結果は待たずにすぐ返る")
        await clock.waitUntilSleeping()
        #expect(session.phase == .resolvingMismatch)
        #expect(session.isInputLocked)
        #expect(session.board.unmatchedFaceUpCards.count == 2)
        #expect(session.flip(cardID: all[2][0].id) == .ignored)
        session.showHint()
        #expect(session.phase == .resolvingMismatch, "ハズレを待つあいだはヒントも効かない")
        clock.advance()
        await session.waitForPendingWork()
        #expect(session.phase == .playing)
        #expect(session.board.unmatchedFaceUpCards.isEmpty)
        #expect(clock.requested == [6, 0.9])
    }

    /// ペアが揃うとすぐに次をめくれる（待たない）
    @Test
    func matchDoesNotWait() async {
        let clock = ImmediateClock()
        let session = makeSession(clock: clock)
        session.start()
        await session.waitForPendingWork()
        let pair = pairs(of: session)[0]
        #expect(session.flip(cardID: pair[0].id) == .firstCard)
        #expect(session.flip(cardID: pair[1].id) == .matched)
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
        await startPlaying(session, clock: clock)

        for _ in 0..<3 {
            session.showHint()
            await clock.waitUntilSleeping()
            #expect(session.phase == .hinting)
            #expect(session.board.cards.allSatisfy { session.isShowingFace(of: $0) })
            #expect(session.flip(cardID: 0) == .ignored)
            clock.advance()
            await session.waitForPendingWork()
            #expect(session.phase == .playing)
            #expect(session.board.cards.allSatisfy { !session.isShowingFace(of: $0) })
        }
        #expect(clock.requested == [6, 1.1, 1.1, 1.1])
    }

    /// 1 枚めくってからヒントを使っても、そのカードは表のままで、続けて 2 枚目をめくれる
    @Test
    func hintKeepsTheFirstCardFaceUp() async {
        let clock = GatedClock()
        let session = makeSession(clock: clock)
        await startPlaying(session, clock: clock)
        let pair = pairs(of: session)[0]
        #expect(session.flip(cardID: pair[0].id) == .firstCard)
        session.showHint()
        await clock.waitUntilSleeping()
        clock.advance()
        await session.waitForPendingWork()
        #expect(session.board.unmatchedFaceUpCards.map(\.id) == [pair[0].id])
        #expect(session.flip(cardID: pair[1].id) == .matched)
    }

    /// 始まる前は、ヒントを押しても何も起きない
    @Test
    func hintIsIgnoredBeforePlaying() {
        let clock = ImmediateClock()
        let session = makeSession(clock: clock)
        session.showHint()
        #expect(session.phase == .ready)
        #expect(clock.requested.isEmpty)
    }

    // MARK: - クリア

    /// 全部揃えると、少し待ってからクリアになる
    @Test
    func matchingAllPairsClearsAfterDelay() async {
        let clock = GatedClock()
        let session = makeSession(.hiragana, .easy, clock: clock)
        await startPlaying(session, clock: clock)

        for pair in pairs(of: session) {
            #expect(session.flip(cardID: pair[0].id) == .firstCard)
            #expect(session.flip(cardID: pair[1].id) == .matched)
        }
        await clock.waitUntilSleeping()
        #expect(session.phase == .finishing)
        #expect(session.remainingPairs == 0)
        #expect(session.isInputLocked)
        clock.advance()
        await session.waitForPendingWork()
        #expect(session.phase == .cleared)
        #expect(clock.requested == [6, 1.3])
    }

    // MARK: - やめる

    /// 揃えた直後（クリアのダイアログを待つあいだ）にやめたら、クリアにしない
    @Test
    func quitWhileFinishingNeverClears() async {
        let clock = GatedClock()
        let session = makeSession(clock: clock)
        await startPlaying(session, clock: clock)
        for pair in pairs(of: session) {
            session.flip(cardID: pair[0].id)
            session.flip(cardID: pair[1].id)
        }
        await clock.waitUntilSleeping()
        #expect(session.phase == .finishing)
        session.quit()
        clock.advance()
        await session.waitForPendingWork()
        #expect(session.phase == .quit)
    }

    /// 全部見せている・ハズレを待つ・ヒントのあいだにやめても、めくれる状態に戻らない
    @Test
    func quitStopsEveryWait() async {
        let clock = GatedClock()
        let revealing = makeSession(clock: clock)
        revealing.start()
        await clock.waitUntilSleeping()
        revealing.quit()
        clock.advance()
        await revealing.waitForPendingWork()
        #expect(revealing.phase == .quit)

        let mismatching = makeSession(clock: clock)
        await startPlaying(mismatching, clock: clock)
        let all = pairs(of: mismatching)
        mismatching.flip(cardID: all[0][0].id)
        mismatching.flip(cardID: all[1][0].id)
        await clock.waitUntilSleeping()
        mismatching.quit()
        clock.advance()
        await mismatching.waitForPendingWork()
        #expect(mismatching.phase == .quit)
        #expect(mismatching.flip(cardID: all[2][0].id) == .ignored)

        let hinting = makeSession(clock: clock)
        await startPlaying(hinting, clock: clock)
        hinting.showHint()
        await clock.waitUntilSleeping()
        hinting.quit()
        clock.advance()
        await hinting.waitForPendingWork()
        #expect(hinting.phase == .quit)
    }
}
