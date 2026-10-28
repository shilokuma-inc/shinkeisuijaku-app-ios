//
//  UITestApp.swift
//  ShinkeisuijakuUITests
//
//  UI テストの補助（起動・要素を待って押す・カードを全部揃える・保護者の確認に答える）。
//  アプリは `-uiTesting` で起動し、メモリ上の保存・擬似のストア・種を固定した乱数・待たない時計に切り替わる（アプリの `UITestingLaunch`）。
//  固定時間では待たない。要素は accessibilityIdentifier で探し、`waitForExistence` などで現れる・消えるのを待ってから押す。
//

import XCTest

/// UI テストで起動したアプリ
@MainActor
struct UITestApp {
    /// 起動のときに選べるもの（アプリの `UITestingLaunch` の起動引数）
    enum Option: String {
        /// 1 回クリアした後の保存で始める（ホームから始まる）
        case clearedOnce = "-uiTestingClearedOnce"
        /// 擬似のストアに、復元で戻るパスの購入を持たせる
        case restorable = "-uiTestingRestorable"
    }

    /// 1 枚のカード（識別子 `play.card.<位置>.pair.<ペア>` から読む。ペアの番号は `-uiTesting` のときだけ付く）
    struct CardInfo {
        let index: Int
        let pairID: Int
        let element: XCUIElement
    }

    /// 現れる・消えるのを待つ長さ。この Mac は負荷が高く、起動や画面の切り替えが遅れることがあるので長めにする
    static let timeout: TimeInterval = 60

    let app: XCUIApplication

    /// 選んだ設定で起動する
    static func launch(_ options: [Option] = []) -> UITestApp {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + options.map(\.rawValue)
        app.launch()
        return UITestApp(app: app)
    }

    /// 識別子の要素
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// 識別子の要素が現れるのを待つ
    @discardableResult
    func waitFor(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = element(identifier)
        XCTAssertTrue(element.waitForExistence(timeout: Self.timeout), "\(identifier) が出ない", file: file, line: line)
        return element
    }

    /// 識別子の要素が消えるのを待つ
    func waitUntilGone(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element(identifier).waitForNonExistence(timeout: Self.timeout), "\(identifier) が消えない", file: file, line: line)
    }

    /// 識別子の要素が現れて押せるようになるのを待って押す
    func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = waitFor(identifier, file: file, line: line)
        XCTAssertTrue(element.wait(for: \.isEnabled, toEqual: true, timeout: Self.timeout), "\(identifier) を押せない", file: file, line: line)
        element.tap()
    }

    /// 要素の読み上げの文が条件を満たすまで待つ
    func waitForLabel(
        _ identifier: String,
        _ matches: @escaping (String) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = waitFor(identifier, file: file, line: line)
        let predicate = NSPredicate { object, _ in
            guard let element = object as? XCUIElement else {
                return false
            }
            return matches(element.label)
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: Self.timeout)
        XCTAssertEqual(result, .completed, "\(identifier) の文が変わらない: \(element.label)", file: file, line: line)
    }

    // MARK: - プレイ

    /// 今の盤面のカード（位置の順）。盤面が出るのを待ってから読む
    func cards(file: StaticString = #filePath, line: UInt = #line) -> [CardInfo] {
        waitFor("play.remainingPairs", file: file, line: line)
        let query = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "play.card."))
        XCTAssertTrue(query.firstMatch.waitForExistence(timeout: Self.timeout), "カードが出ない", file: file, line: line)
        return query.allElementsBoundByIndex.compactMap { element in
            // play.card.<位置>.pair.<ペア>
            let parts = element.identifier.split(separator: ".")
            guard parts.count == 5, parts[3] == "pair", let index = Int(parts[2]), let pairID = Int(parts[4]) else {
                XCTFail("カードの識別子にペアの番号が無い: \(element.identifier)", file: file, line: line)
                return nil
            }
            return CardInfo(index: index, pairID: pairID, element: element)
        }
        .sorted { $0.index < $1.index }
    }

    /// 全部のペアを揃えて、クリアのダイアログが出るのを待つ
    /// - Parameter pairCount: 盤面のペアの数（難易度のペアの数と同じか確かめる）
    func clearBoard(pairCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cards = cards(file: file, line: line)
        XCTAssertEqual(cards.count, pairCount * 2, "カードの枚数", file: file, line: line)
        let pairs = Dictionary(grouping: cards, by: \.pairID).values.sorted { $0[0].pairID < $1[0].pairID }
        XCTAssertEqual(pairs.count, pairCount, "ペアの数", file: file, line: line)
        for pair in pairs {
            XCTAssertEqual(pair.count, 2, "ペアの枚数", file: file, line: line)
            pair.forEach { $0.element.tap() }
        }
        waitFor("clear.dialog", file: file, line: line)
    }

    // MARK: - 保護者の確認

    /// 出ている保護者の確認の問題の答え（問題の文「問題 12 足す 7」はもともと読み上げてよいので、読んで計算する）
    func parentalGateAnswer(file: StaticString = #filePath, line: UInt = #line) -> Int {
        let label = waitFor("parentalGate.question", file: file, line: line).label
        let numbers = label.split { !$0.isASCII || !$0.isNumber }.compactMap { Int($0) }
        XCTAssertEqual(numbers.count, 2, "問題の文から 2 つの数を読めない: \(label)", file: file, line: line)
        return numbers.reduce(0, +)
    }

    /// 保護者の確認に数を入れて「決定」を押す
    func submitParentalGate(_ value: Int, file: StaticString = #filePath, line: UInt = #line) {
        for digit in String(value) {
            tap("parentalGate.key.\(digit)", file: file, line: line)
        }
        tap("parentalGate.submit", file: file, line: line)
    }

    /// 保護者の確認に正しく答えて、ダイアログが閉じるのを待つ
    func passParentalGate(file: StaticString = #filePath, line: UInt = #line) {
        submitParentalGate(parentalGateAnswer(file: file, line: line), file: file, line: line)
        waitUntilGone("parentalGate.dialog", file: file, line: line)
    }
}
