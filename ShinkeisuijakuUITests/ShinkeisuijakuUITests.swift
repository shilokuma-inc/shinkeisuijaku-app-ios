//
//  ShinkeisuijakuUITests.swift
//  ShinkeisuijakuUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class ShinkeisuijakuUITests: XCTestCase {
    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    @MainActor
    func testFirstLaunchStartsGame() throws {
        let app = XCUIApplication()
        // メモリ上の保存に切り替え、Simulator の実際の UserDefaults を使わない（アプリの AppDataStoreFactory.uiTestingArgument）
        app.launchArguments = ["-uiTesting"]
        app.launch()

        // 初めて起動したとき（保存が空）は、ホームを通らずにプレイ画面が開く
        XCTAssertTrue(app.descendants(matching: .any)["play.remainingPairs"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["home.play"].exists)
    }
}
