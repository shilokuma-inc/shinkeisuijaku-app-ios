//
//  PlayFlowUITests.swift
//  ShinkeisuijakuUITests
//
//  初めて起動してからの流れ（すぐプレイ → 全部揃えてクリア → ホーム・スタンプちょう・もう一回・鍵の付いた次の難易度）を確かめる。
//  カードの並びは決め打ちにせず、`-uiTesting` のときだけカードの識別子に付くペアの番号で揃える組を見つける。
//

import XCTest

final class PlayFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 初回の起動はホームを通らずにプレイ（どうぶつ・やさしい）→ 全部揃えてクリア（スタンプをもらう）→ ホーム →
    /// スタンプちょう（集めた数が 1 / 12）→ ホームにもどる
    @MainActor
    func testFirstClearGoesHomeAndStampBookCountsOne() throws {
        let ui = UITestApp.launch()
        ui.waitFor("play.remainingPairs")
        XCTAssertFalse(ui.element("home.play").exists, "初回の起動はホームを通らない")
        ui.clearBoard(pairCount: 6)
        XCTAssertTrue(ui.app.staticTexts["あたらしい スタンプを ゲット"].exists, "はじめてのクリアでスタンプをもらう")
        ui.tap("clear.home")
        ui.waitFor("home.play")
        ui.waitUntilGone("play.remainingPairs")

        ui.tap("home.stampBook")
        ui.waitForLabel("stampBook.count") { $0.contains("12 こ の うち 1 こ") }
        ui.tap("stampBook.home")
        ui.waitFor("home.play")
        ui.waitUntilGone("stampBook")
    }

    /// クリア → もう一回あそぶ → もう一度クリアすると、スタンプが 2 つになる
    @MainActor
    func testPlayAgainAfterClearAwardsSecondStamp() throws {
        let ui = UITestApp.launch()
        ui.clearBoard(pairCount: 6)
        ui.tap("clear.playAgain")
        ui.waitUntilGone("clear.dialog")
        ui.clearBoard(pairCount: 6)
        ui.tap("clear.stampBook")
        ui.waitForLabel("stampBook.count") { $0.contains("12 こ の うち 2 こ") }
    }

    /// クリアの鍵の付いた次の難易度（ふつう）→ 案内「おうちの方に あけてもらってね」→ 案内の下の「おうちの方へ」→ 保護者の確認が出る
    @MainActor
    func testLockedNextDifficultyShowsGuideThenParentalGate() throws {
        let ui = UITestApp.launch()
        ui.clearBoard(pairCount: 6)
        XCTAssertFalse(ui.element("clear.lockedGuide").exists, "押すまでは案内を出さない")
        ui.tap("clear.nextDifficulty")
        ui.waitForLabel("clear.lockedGuide") { $0.contains("おうちの方に あけてもらってね") }
        XCTAssertTrue(ui.element("clear.dialog").exists, "鍵が付いているのでゲームは始めない")
        ui.tap("clear.lockedGuideParents")
        ui.waitFor("parentalGate.dialog")
        XCTAssertFalse(ui.element("parents").exists, "確認を通るまでは、おうちの方への画面を出さない")
    }

    /// 初回の起動のゲームで、左端からスワイプしてもホームに戻らない（戻るのは「やめる」で確かめてからだけ）
    @MainActor
    func testEdgeSwipeDoesNotLeaveFirstGame() throws {
        let ui = UITestApp.launch()
        let cardsBefore = ui.cards()
        let start = ui.app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = ui.app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        // スワイプの後はアプリが落ち着くまで XCUITest が待つので、戻る動きが起きていれば、ここではもう終わっている
        XCTAssertTrue(ui.element("play.remainingPairs").isHittable)
        XCTAssertFalse(ui.element("home.play").exists)
        XCTAssertEqual(ui.cards().map(\.pairID), cardsBefore.map(\.pairID), "同じゲームのまま")
    }
}
