//
//  LaunchRulesTests.swift
//  ShinkeisuijakuTests
//
//  起動したときにどこから始めるかと、ホームの「あそぶ」で始めるゲームの決まりを確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct LaunchRulesTests {
    /// 初めて起動したときは、ホームを通らず どうぶつ・やさしい から始める
    @Test
    func firstLaunchStartsAnimalsEasy() {
        #expect(LaunchRules.startsWithGame(.initial))
        #expect(LaunchRules.launchGame(.initial) == GameChoice(course: .animals, difficulty: .easy))
    }

    /// 初回クリア前なら、前回ひらがなで遊んでやめていても、どうぶつ・やさしい から始める
    @Test
    func beforeFirstClearAlwaysStartsFirstGame() {
        let data = AppData(lastCourse: .hiragana, lastDifficulty: .easy, hasClearedOnce: false)
        #expect(LaunchRules.launchGame(data) == LaunchRules.firstGame)
    }

    /// 1 回クリアした後は、ホームから始める
    @Test
    func afterFirstClearStartsAtHome() {
        let data = AppData(hasClearedOnce: true)
        #expect(!LaunchRules.startsWithGame(data))
        #expect(LaunchRules.launchGame(data) == nil)
    }

    /// 「あそぶ」は前回のコースと難易度で始める
    @Test(arguments: Course.allCases, Difficulty.allCases)
    func resumeUsesLastChoiceWithPass(course: Course, difficulty: Difficulty) {
        let data = AppData(lastCourse: course, lastDifficulty: difficulty, hasClearedOnce: true)
        #expect(LaunchRules.resumeGame(data, hasPass: true) == GameChoice(course: course, difficulty: difficulty))
    }

    /// 前回の難易度に鍵が付いている（パスの権利が無い）ときは、そのコースのやさしいで始める
    @Test(arguments: Course.allCases, [Difficulty.normal, .hard])
    func lockedLastDifficultyFallsBackToEasy(course: Course, difficulty: Difficulty) {
        let data = AppData(lastCourse: course, lastDifficulty: difficulty, hasClearedOnce: true)
        #expect(LaunchRules.resumeGame(data, hasPass: false) == GameChoice(course: course, difficulty: .easy))
    }

    /// やさしいはパスが無くてもそのまま始める
    @Test
    func easyNeedsNoPass() {
        let data = AppData(lastCourse: .hiragana, lastDifficulty: .easy, hasClearedOnce: true)
        #expect(LaunchRules.resumeGame(data, hasPass: false) == GameChoice(course: .hiragana, difficulty: .easy))
    }
}
