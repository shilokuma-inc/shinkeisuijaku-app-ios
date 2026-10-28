//
//  CourseSelectionTests.swift
//  ShinkeisuijakuTests
//
//  コース選択のダイアログの決まり（鍵が付くか・押したときに始めるか案内か・読み上げ）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct CourseSelectionTests {
    /// 難易度は やさしい・ふつう・むずかしい の順に 3 つ並べ、ペアの数を右に出す
    @Test
    func optionsListThreeDifficultiesInOrder() {
        let options = CourseSelection.options(hasPass: false)
        #expect(options.map(\.difficulty) == [.easy, .normal, .hard])
        #expect(options.map(\.pairsText) == ["6ペア", "8ペア", "10ペア"])
    }

    /// パスの権利が無ければ、ふつう・むずかしいに鍵が付き、やさしいには付かない
    @Test
    func normalAndHardAreLockedWithoutPass() {
        let options = CourseSelection.options(hasPass: false)
        #expect(options.map(\.isLocked) == [false, true, true])
    }

    /// 購入後は鍵を出さない
    @Test
    func noLocksWithPass() {
        let options = CourseSelection.options(hasPass: true)
        #expect(options.allSatisfy { !$0.isLocked })
    }

    /// 鍵の無い難易度を押すと、そのコースと難易度のゲームを始める（案内は出さない）
    @Test(arguments: Course.allCases)
    func unlockedDifficultyStartsGame(course: Course) {
        var selection = CourseSelection(course: course)
        #expect(selection.select(.easy, hasPass: false) == .start(GameChoice(course: course, difficulty: .easy)))
        #expect(!selection.showsLockedGuide(hasPass: false))
        #expect(selection.lockedDifficulty == nil)
    }

    /// パスの権利があれば、ふつう・むずかしいも押すとゲームを始める
    @Test(arguments: [Difficulty.normal, .hard])
    func passUnlocksDifficulty(difficulty: Difficulty) {
        var selection = CourseSelection(course: .hiragana)
        #expect(selection.select(difficulty, hasPass: true) == .start(GameChoice(course: .hiragana, difficulty: difficulty)))
    }

    /// 鍵の付いた難易度を押すと、ゲームは始めずに案内を出し、押した難易度を覚える
    @Test(arguments: [Difficulty.normal, .hard])
    func lockedDifficultyShowsGuide(difficulty: Difficulty) {
        var selection = CourseSelection(course: .animals)
        #expect(!selection.showsLockedGuide(hasPass: false), "押す前は案内を出さない")
        #expect(selection.select(difficulty, hasPass: false) == .showLockedGuide)
        #expect(selection.showsLockedGuide(hasPass: false))
        #expect(selection.lockedDifficulty == difficulty)
    }

    /// 案内を出したまま購入したら、案内を消す
    @Test
    func guideHidesAfterPurchase() {
        var selection = CourseSelection(course: .animals)
        _ = selection.select(.normal, hasPass: false)
        #expect(!selection.showsLockedGuide(hasPass: true))
    }

    /// 読み上げは「ふつう 8ペア かぎ」のように、鍵が付いているかを言葉で伝える
    @Test
    func accessibilityLabelSaysLockState() {
        let locked = CourseSelection.options(hasPass: false)
        #expect(locked.map(\.accessibilityLabel) == ["やさしい 6ペア", "ふつう 8ペア かぎ", "むずかしい 10ペア かぎ"])
        let unlocked = CourseSelection.options(hasPass: true)
        #expect(unlocked.map(\.accessibilityLabel) == ["やさしい 6ペア", "ふつう 8ペア", "むずかしい 10ペア"])
    }
}
