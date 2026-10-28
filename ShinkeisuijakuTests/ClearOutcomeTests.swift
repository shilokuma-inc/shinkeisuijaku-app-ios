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
}
