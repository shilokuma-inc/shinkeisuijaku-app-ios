//
//  ClearOutcomeTests.swift
//  ShinkeisuijakuTests
//
//  クリアしたときに決めること（スタンプ・保存・ダイアログに出すもの）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct ClearOutcomeTests {
    private func clear(
        _ course: Course,
        _ difficulty: Difficulty,
        data: AppData = .initial,
        hasPass: Bool = false
    ) -> ClearOutcome {
        var generator = SeededRandomNumberGenerator(seed: 3)
        return ClearOutcome.make(course: course, difficulty: difficulty, data: data, hasPass: hasPass, using: &generator)
    }

    /// クリアすると、スタンプを 1 つ足し、初回クリア済み・前回のコースと難易度を記録する
    @Test
    func clearRecordsStampAndProgress() throws {
        let outcome = clear(.hiragana, .easy)
        let stamp = try #require(outcome.awardedStamp)
        #expect(outcome.data.ownedStampIDs == [stamp.id])
        #expect(outcome.data.hasClearedOnce)
        #expect(outcome.data.lastCourse == .hiragana)
        #expect(outcome.data.lastDifficulty == .easy)
    }

    /// ほかの保存の項目（パスのキャッシュ）はそのまま
    @Test
    func clearKeepsOtherData() {
        let data = AppData(
            ownedStampIDs: ["regular.cat"],
            hasPassCache: true,
            lastCourse: .animals,
            lastDifficulty: .normal,
            hasClearedOnce: true
        )
        let outcome = clear(.animals, .hard, data: data, hasPass: true)
        #expect(outcome.data.hasPassCache)
        #expect(outcome.data.ownedStampIDs == ["regular.cat", "pass.animals.gold"])
        #expect(outcome.awardedStamp == .pass(.animals, .gold))
    }

    /// 通常のスタンプが全部そろった後は、スタンプは増えず（ほめ言葉だけ）、初回クリア済みなどは記録する
    @Test
    func clearAfterCollectingEverythingAddsNothing() {
        let data = AppData(ownedStampIDs: Stamp.regularStamps.map(\.id))
        let outcome = clear(.animals, .easy, data: data)
        #expect(outcome.awardedStamp == nil)
        #expect(outcome.data.ownedStampIDs == data.ownedStampIDs)
        #expect(outcome.data.hasClearedOnce)
    }

    /// 次の難易度: やさしい → ふつう、ふつう → むずかしい、むずかしいでは出さない。パスが無いと鍵が付く
    @Test
    func nextDifficultyAndLock() {
        let easy = clear(.animals, .easy)
        #expect(easy.nextDifficulty == .normal)
        #expect(easy.isNextDifficultyLocked(hasPass: false))
        #expect(!easy.isNextDifficultyLocked(hasPass: true))
        let normal = clear(.animals, .normal, hasPass: true)
        #expect(normal.nextDifficulty == .hard)
        let hard = clear(.animals, .hard, hasPass: true)
        #expect(hard.nextDifficulty == nil)
        #expect(!hard.isNextDifficultyLocked(hasPass: false))
    }

    /// 「もっと むずかしいのは おうちの方へ」はパスを買った後は出さない
    @Test
    func parentsGuideOnlyWithoutPass() {
        #expect(ClearOutcome.showsParentsGuide(hasPass: false))
        #expect(!ClearOutcome.showsParentsGuide(hasPass: true))
    }

    /// クリアの振動は 40 ミリ秒の振動を 60 ミリ秒あけて 2 回
    @Test
    func clearHapticPatternIsFortySixtyForty() {
        let pulses = ClearHapticPattern.pulses
        #expect(pulses.count == 2)
        #expect(pulses.map(\.start) == [0, 0.1])
        #expect(pulses.allSatisfy { $0.duration == 0.04 })
    }

    /// クリアの記録は、保存と振動を 1 回だけ行い、同じゲームで二度呼んでもスタンプを増やさない
    @Test
    func recorderRecordsOnlyOnce() {
        let store = InMemoryAppDataStore()
        let haptics = SilentHaptics()
        let recorder = ClearRecorder(course: .animals, difficulty: .easy)
        var generator = SeededRandomNumberGenerator(seed: 5)
        let first = recorder.record(store: store, hasPass: false, haptics: haptics, using: &generator)
        let second = recorder.record(store: store, hasPass: false, haptics: haptics, using: &generator)
        #expect(first == second)
        #expect(store.saveCount == 1)
        #expect(haptics.clearedCount == 1)
        #expect(store.data.ownedStampIDs.count == 1)
        #expect(store.data.hasClearedOnce)
        #expect(recorder.outcome == first)
    }

    /// クリアの大きなスタンプは、もらったスタンプの名前を読み上げる。全部そろった後の飾りのホシは読み上げない
    @Test
    func stampAccessibilityLabelNamesTheAwardedStamp() {
        let regular = ClearOutcome(
            course: .animals,
            difficulty: .easy,
            awardedStamp: .regular(.cat),
            data: .initial
        )
        #expect(regular.stampAccessibilityLabel == "ネコ の スタンプ")
        let pass = ClearOutcome(
            course: .hiragana,
            difficulty: .hard,
            awardedStamp: .pass(.hiragana, .gold),
            data: .initial
        )
        #expect(pass.stampAccessibilityLabel == "ひらがな むずかしい の とくべつな スタンプ")
        let allCollected = clear(.animals, .easy, data: AppData(ownedStampIDs: Stamp.regularStamps.map(\.id)))
        #expect(allCollected.awardedStamp == nil)
        #expect(allCollected.stampAccessibilityLabel == nil)
    }
}
