//
//  UITestingLaunchTests.swift
//  ShinkeisuijakuTests
//
//  UI テストの起動引数の切り替え（`UITestingLaunch`）を確かめる。
//  `-uiTesting` が無ければほかの UI テスト用の引数が効かないこと、カードの識別子に答えの手がかりを出さないこと、
//  `-uiTesting` のときは種を固定した乱数・待たない時計・選んだ初期の保存と擬似のストアで画面の流れを作ること。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

@Suite(.timeLimit(.minutes(1)))
struct UITestingLaunchTests {
    // MARK: - 通常の起動では効かない

    /// `-uiTesting` が無ければ、ほかの UI テスト用の引数があっても UI テストの設定にならない
    @Test
    func optionsNeedUITestingArgument() {
        #expect(UITestingLaunch(arguments: []) == nil)
        #expect(UITestingLaunch(arguments: [UITestingLaunch.clearedOnceArgument, UITestingLaunch.restorableArgument]) == nil)
    }

    /// Unit テストのホスト（UI テストの起動引数を渡していない）では、今の起動の設定は無い
    @Test
    func currentLaunchIsNotUITesting() {
        #expect(UITestingLaunch.current == nil)
    }

    /// 通常の起動では、カードの識別子は位置の番号だけで、ペアの番号（どれとどれが揃うか）を出さない
    @Test
    func cardIdentifierHidesPairsOutsideUITesting() {
        #expect(UITestingLaunch.cardIdentifier(index: 3, pairID: 1, launch: nil) == "play.card.3")
        #expect(UITestingLaunch.cardIdentifier(index: 3, pairID: 1) == "play.card.3", "Unit テストのホストも通常の起動と同じ")
    }

    // MARK: - UI テストの起動

    /// UI テストのときだけ、カードの識別子にペアの番号を付ける
    @Test
    func cardIdentifierShowsPairsInUITesting() throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument]))
        #expect(UITestingLaunch.cardIdentifier(index: 3, pairID: 1, launch: launch) == "play.card.3.pair.1")
    }

    /// 引数を選ばなければ、初めて起動したときの保存で始め、ゲームから始まる
    @Test
    func defaultStartsFresh() throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument]))
        #expect(!launch.startsClearedOnce)
        #expect(!launch.hasRestorablePass)
        #expect(launch.initialData == .initial)
        let flow = launch.makeFlow()
        #expect(flow.path == [.game])
        #expect(!flow.hasPass)
    }

    /// 1 回クリアした後の保存を選ぶと、ホームから始まる
    @Test
    func clearedOnceStartsAtHome() throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument, UITestingLaunch.clearedOnceArgument]))
        #expect(launch.initialData.hasClearedOnce)
        let flow = launch.makeFlow()
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
    }

    /// 復元できる購入を選ぶと、擬似のストアの復元で権利が付く（選ばなければ見つからない）
    @Test(arguments: [true, false])
    func restorableOptionDecidesRestore(restorable: Bool) async throws {
        let arguments = [UITestingLaunch.argument] + (restorable ? [UITestingLaunch.restorableArgument] : [])
        let flow = try #require(UITestingLaunch(arguments: arguments)).makeFlow()
        let result = await flow.passStore.restore()
        #expect(result == (restorable ? .restored : .notFound))
        #expect(flow.hasPass == restorable)
    }

    /// カードの配り方は固定した種から決まる（並びを決め打ちにせず、同じ種で配ったものと比べる）
    @Test
    func dealUsesFixedSeed() throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument]))
        let session = try #require(launch.makeFlow().session)
        var generator = SeededRandomNumberGenerator(seed: UITestingLaunch.seed)
        let expected = GameDealer.deal(course: session.course, difficulty: session.difficulty, using: &generator)
        #expect(session.board == expected)
        let relaunched = try #require(launch.makeFlow().session)
        #expect(relaunched.board == session.board, "起動し直しても同じ並び")
    }

    /// 保護者の確認の問題も固定した種から決まる
    @Test
    func parentalGateUsesFixedSeed() throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument]))
        var first = launch.makeFlow().parentalGateGenerator
        var second = launch.makeFlow().parentalGateGenerator
        var seeded = SeededRandomNumberGenerator(seed: UITestingLaunch.seed)
        let expected = ParentalGateQuestion.make(using: &seeded)
        #expect(ParentalGateQuestion.make(using: &first) == expected)
        #expect(ParentalGateQuestion.make(using: &second) == expected)
    }

    /// 待ち時間は無く、全部見せたらすぐめくれるようになり、揃えたらすぐクリアになる
    @Test
    func timingDoesNotWait() async throws {
        let launch = try #require(UITestingLaunch(arguments: [UITestingLaunch.argument]))
        let session = try #require(launch.makeFlow().session)
        #expect(session.isBeforeFirstClear, "初回クリア前の 4.8 秒も待たない")
        #expect(GameTiming.uiTesting.revealAll(session.difficulty.pairCount, true) == 0)
        #expect(GameTiming.uiTesting.mismatchDelay == 0)
        #expect(GameTiming.uiTesting.hintDuration == 0)
        #expect(GameTiming.uiTesting.clearDialogDelay == 0)
        session.start()
        await session.waitForPendingWork()
        #expect(session.phase == .playing)
        let pairs = Dictionary(grouping: session.board.cards, by: \.pairID).values
        for pair in pairs {
            session.flip(cardID: pair[0].id)
            session.flip(cardID: pair[1].id)
        }
        await session.waitForPendingWork()
        #expect(session.phase == .cleared)
    }
}
