//
//  PurchaseFlowUITests.swift
//  ShinkeisuijakuUITests
//
//  ホームからの購入の流れ（仕様書の「ロックされた難易度を押したとき」）と、保護者の確認のやめる・購入の復元を確かめる。
//  1 回クリアした後の保存（ホームから始まる）と擬似のストアで起動する。保護者の確認は、問題の文を読んで答えを計算する。
//

import XCTest

final class PurchaseFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// ホーム → 「ほかの あそびかた」→ コース選択 → 鍵の付いた ふつう → 案内 → 案内の下の「おうちの方へ」→
    /// 保護者の確認で間違えた答え（問題が変わる）→ 正しい答え → おうちの方への画面 → 擬似の購入 → 押した ふつう のゲームが始まる
    @MainActor
    func testPurchaseFromLockedCourseStartsPressedDifficulty() throws {
        let ui = UITestApp.launch([.clearedOnce])
        openLockedGuide(ui, course: "animals", difficulty: "normal")
        ui.tap("courseSelect.lockedGuideParents")
        ui.waitUntilGone("courseSelect.dialog")

        // 間違えると、入れた答えを消して別の問題に変える
        let question = ui.waitFor("parentalGate.question").label
        let answer = ui.parentalGateAnswer()
        ui.submitParentalGate(answer == 99 ? answer - 1 : answer + 1)
        ui.waitFor("parentalGate.wrongNotice")
        ui.waitForLabel("parentalGate.question") { $0 != question }
        XCTAssertFalse(ui.element("parents").exists, "間違えたら、おうちの方への画面に進まない")

        ui.passParentalGate()
        ui.waitFor("parents")
        ui.waitForLabel("parents.price") { $0.contains("¥100") }
        ui.tap("parents.purchase")

        // 購入が終わったら、押した難易度（ふつう・8 ペア）のゲームがすぐ始まる
        ui.waitUntilGone("parents")
        XCTAssertEqual(ui.cards().count, 16, "ふつうは 8 ペア")
        XCTAssertFalse(ui.element("home.play").exists)
    }

    /// 保護者の確認の「やめる」で、コース選択に戻らずホームに戻る（購入の案内をくり返し出さない）
    @MainActor
    func testCancellingParentalGateGoesHome() throws {
        let ui = UITestApp.launch([.clearedOnce])
        openLockedGuide(ui, course: "hiragana", difficulty: "hard")
        ui.tap("courseSelect.lockedGuideParents")
        ui.tap("parentalGate.cancel")
        ui.waitUntilGone("parentalGate.dialog")
        XCTAssertTrue(ui.waitFor("home.play").isHittable)
        XCTAssertFalse(ui.element("courseSelect.dialog").exists)
        XCTAssertFalse(ui.element("parents").exists)
    }

    /// 擬似のストアに復元できる購入があるとき、おうちの方への画面の「購入を復元」で購入済みになり、コース選択の鍵が消える
    @MainActor
    func testRestoreUnlocksCourseSelection() throws {
        let ui = UITestApp.launch([.clearedOnce, .restorable])
        ui.tap("home.course.animals")
        ui.waitForLabel("courseSelect.difficulty.normal") { $0.contains("かぎ") }
        ui.tap("courseSelect.close")
        ui.waitUntilGone("courseSelect.dialog")

        ui.tap("home.parents")
        ui.passParentalGate()
        ui.tap("parents.restore")
        ui.waitForLabel("parents.message") { $0.contains("購入を復元しました") }
        ui.waitFor("parents.purchased")
        XCTAssertFalse(ui.element("parents.purchase").exists, "購入済みなら購入のボタンを出さない")
        ui.tap("parents.home")
        ui.waitUntilGone("parents")

        ui.tap("home.course.animals")
        for difficulty in ["easy", "normal", "hard"] {
            ui.waitForLabel("courseSelect.difficulty.\(difficulty)") { !$0.contains("かぎ") }
        }
        ui.tap("courseSelect.difficulty.normal")
        XCTAssertEqual(ui.cards().count, 16, "鍵が消えたので、ふつうがすぐ始まる")
    }

    /// ホームの「ほかの あそびかた」のコースからコース選択を開き、鍵の付いた難易度を押して案内を出す
    @MainActor
    private func openLockedGuide(_ ui: UITestApp, course: String, difficulty: String, file: StaticString = #filePath, line: UInt = #line) {
        ui.tap("home.course.\(course)", file: file, line: line)
        ui.waitForLabel("courseSelect.difficulty.\(difficulty)", { $0.contains("かぎ") }, file: file, line: line)
        XCTAssertFalse(ui.element("courseSelect.lockedGuide").exists, "押すまでは案内を出さない", file: file, line: line)
        ui.tap("courseSelect.difficulty.\(difficulty)", file: file, line: line)
        ui.waitForLabel("courseSelect.lockedGuide", { $0.contains("おうちの方に あけてもらってね") }, file: file, line: line)
        XCTAssertFalse(ui.element("play.remainingPairs").exists, "鍵が付いているのでゲームは始めない", file: file, line: line)
    }
}
