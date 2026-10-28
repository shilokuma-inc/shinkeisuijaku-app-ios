//
//  AppFlowWindowsTests.swift
//  ShinkeisuijakuTests
//
//  iPad で窓が 2 つ開いたとき（画面の流れを窓ごとに作り、保存とストアはアプリで 1 つを共有する）に、
//  片方の窓のクリア・やめる・閉じるがもう片方に重ならないことを確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct AppFlowWindowsTests {
    /// アプリで 1 つの保存とストアと、それを共有する 2 つの窓の画面の流れ
    private struct TwoWindows {
        let store: InMemoryAppDataStore
        let services: AppServices
        let first: AppFlow
        let second: AppFlow
    }

    private func makeTwoWindows(data: AppData = .initial, entitled: Bool = false) -> TwoWindows {
        let store = InMemoryAppDataStore(data: data)
        let passStore = PassStore(backend: FakePassStoreBackend(entitled: entitled), dataStore: store)
        let services = AppServices(store: store, passStore: passStore, haptics: SilentHaptics())
        return TwoWindows(
            store: store,
            services: services,
            first: makeFlow(services, seed: 1),
            second: makeFlow(services, seed: 2)
        )
    }

    /// 窓 1 つ分の画面の流れ（`AppFlow.makeForLaunch(services:)` と同じく、保存とストアを共有する）
    private func makeFlow(_ services: AppServices, seed: UInt64) -> AppFlow {
        AppFlow(
            store: services.store,
            passStore: services.passStore,
            haptics: services.haptics,
            clock: InstantGameClock(),
            generator: SeededRandomNumberGenerator(seed: seed)
        )
    }

    /// 窓ごとの画面の流れは別のものだが、保存とストアはアプリで 1 つを共有する
    @Test
    func windowsShareStoreAndPassStore() {
        let services = makeTwoWindows().services
        let first = AppFlow.makeForLaunch(services: services)
        let second = AppFlow.makeForLaunch(services: services)
        #expect(first !== second)
        #expect(first.store === second.store)
        #expect(first.passStore === second.passStore)
    }

    /// 初回クリア前に 2 つの窓を開くと、窓ごとに別のゲームが始まる
    @Test
    func eachWindowHasItsOwnGame() throws {
        let windows = makeTwoWindows()
        let first = try #require(windows.first.session)
        let second = try #require(windows.second.session)
        #expect(first !== second)
        #expect(windows.first.path == [.game])
        #expect(windows.second.path == [.game])
    }

    /// 片方の窓のクリアでもらうスタンプは 1 つだけで、もう片方の窓のゲームはクリアにならない（Q7: 1 回のクリアで 1 つまで）
    @Test
    func clearInOneWindowAwardsOneStamp() throws {
        let windows = makeTwoWindows()
        let secondSession = try #require(windows.second.session)
        windows.first.recordClear()
        // 同じ窓で二度記録しても（ダイアログの出し直しなど）、増えない
        windows.first.recordClear()
        #expect(windows.store.data.ownedStampIDs.count == 1)
        #expect(windows.second.session === secondSession)
        #expect(secondSession.phase != .cleared)
    }

    /// 両方の窓でクリアしたときは、それぞれ 1 つずつもらい、先にもらったスタンプを後のクリアで上書きしない
    @Test
    func clearsInBothWindowsKeepEachStamp() throws {
        let windows = makeTwoWindows()
        let firstOutcome = try #require(windows.first.recordClear())
        let secondOutcome = try #require(windows.second.recordClear())
        let firstStamp = try #require(firstOutcome.awardedStamp)
        let secondStamp = try #require(secondOutcome.awardedStamp)
        #expect(firstStamp != secondStamp, "後の窓は、先の窓のクリアを保存から読み直してから選ぶ")
        #expect(windows.store.data.ownedStampIDs == [firstStamp.id, secondStamp.id])
    }

    /// パスがあり 2 つの窓で同じコースの ふつう を続けてクリアしても、パス専用のスタンプは先の窓の 1 回だけで、後の窓は通常のスタンプになる（Q7）
    @Test
    func passStampOnlyOnceAcrossWindows() throws {
        // パスの権利は StoreKit で確かめるまで端末内のキャッシュなので、キャッシュも持たせる
        let windows = makeTwoWindows(data: AppData(hasPassCache: true, hasClearedOnce: true), entitled: true)
        let choice = GameChoice(course: .animals, difficulty: .normal)
        windows.first.startGame(choice)
        windows.second.startGame(choice)
        let firstStamp = try #require(windows.first.recordClear()?.awardedStamp)
        let secondStamp = try #require(windows.second.recordClear()?.awardedStamp)
        #expect(firstStamp == .pass(.animals, .silver))
        guard case .regular = secondStamp else {
            Issue.record("後の窓は通常のスタンプになる: \(secondStamp)")
            return
        }
        #expect(windows.store.data.ownedStampIDs.count == 2)
    }

    /// 片方の窓で「やめる」・窓を閉じる（プレイ画面がゲームを止める）と、その窓のゲームだけが止まり、もう片方のゲームは続く
    @Test
    func quittingOneWindowKeepsOtherGame() async throws {
        let windows = makeTwoWindows()
        let first = try #require(windows.first.session)
        let second = try #require(windows.second.session)
        first.start()
        second.start()
        await first.waitForPendingWork()
        await second.waitForPendingWork()
        first.quit()
        windows.first.goHome()
        #expect(first.phase == .quit)
        #expect(second.phase == .playing)
        #expect(windows.second.path == [.game])
    }

    /// 初回クリア前に後から開いた窓の、起動してすぐのゲーム（どうぶつ・やさしい）は、先の窓で選んだ前回のコースと難易度を保存し直さない
    @Test
    func launchGameInNewWindowKeepsLastChoice() throws {
        let windows = makeTwoWindows()
        windows.first.startGame(GameChoice(course: .hiragana, difficulty: .easy))
        let savesBefore = windows.store.saveCount
        let third = makeFlow(windows.services, seed: 3)
        let launched = try #require(third.session)
        #expect(launched.course == .animals)
        #expect(launched.difficulty == .easy)
        #expect(windows.store.saveCount == savesBefore, "起動してすぐのゲームでは保存しない")
        #expect(windows.store.data.lastCourse == .hiragana)
        #expect(windows.store.data.lastDifficulty == .easy)
    }

    /// 片方の窓で買ったパスは、ストアを共有するもう片方の窓でもすぐ使える
    @Test
    func purchaseInOneWindowUnlocksOther() async {
        let windows = makeTwoWindows(data: AppData(hasClearedOnce: true))
        #expect(!windows.second.hasPass)
        windows.first.openParents()
        windows.first.parentalGatePassed()
        #expect(await windows.first.passStore.purchase() == .purchased)
        #expect(windows.second.hasPass)
        #expect(windows.second.path.isEmpty, "もう片方の窓の画面は変えない")
    }
}
