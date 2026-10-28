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
    func testLaunchShowsContentView() throws {
        let app = XCUIApplication()
        // メモリ上の保存に切り替え、Simulator の実際の UserDefaults を使わない（アプリの AppDataStoreFactory.uiTestingArgument）
        app.launchArguments = ["-uiTesting"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Hello, world!"].waitForExistence(timeout: 5))
    }
}
