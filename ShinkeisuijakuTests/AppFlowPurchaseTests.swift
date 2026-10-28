//
//  AppFlowPurchaseTests.swift
//  ShinkeisuijakuTests
//
//  購入の流れ（仕様書の「ロックされた難易度を押したとき」）を、画面の流れ・おうちの方への画面の状態・擬似のストアで通して確かめる。
//  鍵の付いた難易度 → おうちの方へ → 保護者の確認 → おうちの方への画面 → 購入 → 押した難易度のゲーム、と、
//  確認をやめたとき・買わずに戻ったとき・クリアから来たとき・購入と返金で鍵が消えて戻ること。
//  `AppFlowTests` に入れると SwiftLint の file_length（500 行）を超えるので、ファイルを分けている。
//

import Foundation
import Observation
@testable import Shinkeisuijaku
import Testing

@Suite(.timeLimit(.minutes(1)))
struct AppFlowPurchaseTests {
    /// テストで使う画面の流れと、その後ろの擬似のストア・保存
    private struct Fixture {
        let flow: AppFlow
        let backend: FakePassStoreBackend
        let store: InMemoryAppDataStore

        /// 開いているおうちの方への画面の状態（画面と同じく、購入が終わったら画面の流れに伝える）
        func parentsModel() -> ParentsModel {
            ParentsModel(passStore: flow.passStore, onPurchased: flow.purchaseCompleted)
        }

        /// おうちの方への画面で「購入する」を押して、終わるまで待つ
        @discardableResult
        func purchase() async -> ParentsModel {
            let model = parentsModel()
            model.request(.purchase)
            await model.runPendingAction()
            return model
        }
    }

    /// 1 回クリアした後（ホームから始まる）・パスの購入前で作る
    private func makeFixture(data: AppData = AppData(hasClearedOnce: true), entitled: Bool = false) -> Fixture {
        let backend = FakePassStoreBackend(entitled: entitled)
        let store = InMemoryAppDataStore(data: data)
        let flow = AppFlow(
            store: store,
            passStore: PassStore(backend: backend, dataStore: store),
            haptics: SilentHaptics(),
            clock: InstantGameClock(),
            generator: SeededRandomNumberGenerator(seed: 7)
        )
        return Fixture(flow: flow, backend: backend, store: store)
    }

    /// 擬似のストアの処理が画面の値に届くまで、ほかの処理に順番を譲って待つ（時間では待たない）。条件が成り立ったかを返す
    private func waitUntil(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<1_000 {
            if condition() {
                return true
            }
            await Task.yield()
        }
        return condition()
    }

    /// コース選択で鍵の付いた難易度を押し、案内の「おうちの方へ」で保護者の確認を出す
    private func openGateFromCourse(_ flow: AppFlow, course: Course, difficulty: Difficulty) throws {
        flow.chooseCourse(course)
        try #require(flow.selectDifficulty(difficulty) == .showLockedGuide)
        flow.openParentsForLockedCourse()
        try #require(flow.isShowingParentalGate)
    }

    // MARK: - コース選択の鍵から

    /// 鍵 → 案内の「おうちの方へ」→ 確認 → おうちの方への画面 → 購入 で、押したコースと難易度のゲームがすぐ始まる
    @Test
    func purchaseFromCourseStartsPressedDifficulty() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        try openGateFromCourse(flow, course: .hiragana, difficulty: .hard)
        #expect(flow.courseSelection == nil, "確認を出すときにダイアログは閉じる")
        #expect(flow.path.isEmpty, "確認を通るまでは、おうちの方への画面を積まない")
        #expect(flow.parentsEntry == .lockedDifficulty(GameChoice(course: .hiragana, difficulty: .hard)))
        flow.parentalGatePassed()
        #expect(flow.path == [.parents])
        #expect(flow.session == nil, "購入するまではゲームを始めない")
        let model = await fixture.purchase()
        #expect(model.message == .purchased)
        #expect(flow.path == [.game])
        let session = try #require(flow.session)
        #expect(session.course == .hiragana)
        #expect(session.difficulty == .hard)
        #expect(fixture.store.data.lastDifficulty == .hard, "始めたゲームは前回のものとして保存する")
        #expect(flow.parentsEntry == nil)
    }

    /// 確認をやめたらホームに戻り、コース選択のダイアログも閉じる。案内をくり返し出さない（あとで何をしても自動で確認を出さない）
    @Test
    func cancellingGateFromCourseGoesHome() throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        try openGateFromCourse(flow, course: .animals, difficulty: .normal)
        flow.cancelParentalGate()
        #expect(!flow.isShowingParentalGate)
        #expect(flow.courseSelection == nil)
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
        #expect(flow.parentsEntry == nil)
        flow.play()
        flow.goHome()
        #expect(!flow.isShowingParentalGate)
        #expect(flow.courseSelection == nil)
    }

    /// おうちの方への画面で買わずに「ホームにもどる」を押したら、ホームへ（押した難易度は捨て、何も始めない）
    @Test
    func homeFromParentsWithoutPurchaseStartsNothing() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        try openGateFromCourse(flow, course: .hiragana, difficulty: .normal)
        flow.parentalGatePassed()
        flow.goHome()
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
        #expect(flow.parentsEntry == nil)
        // ホームの「おうちの方へ」から開き直して買っても、捨てた難易度は始めない
        flow.openParents()
        flow.parentalGatePassed()
        await fixture.purchase()
        #expect(flow.hasPass)
        #expect(flow.path == [.parents])
        #expect(flow.session == nil)
    }

    /// 鍵の付いた難易度を押す前（案内を出していない）は、案内の「おうちの方へ」が届いても何もしない
    @Test
    func lockedCourseParentsNeedsGuide() {
        let flow = makeFixture().flow
        flow.chooseCourse(.animals)
        flow.openParentsForLockedCourse()
        #expect(!flow.isShowingParentalGate)
        #expect(flow.courseSelection == CourseSelection(course: .animals))
    }

    // MARK: - クリアの次の難易度の鍵から

    /// クリアの鍵の付いた次の難易度 → 案内の「おうちの方へ」→ 確認 → 購入 で、同じコースの次の難易度がすぐ始まる
    @Test
    func purchaseFromClearStartsNextDifficulty() async throws {
        // 初回クリア前の起動（どうぶつ・やさしい）から始める
        let fixture = makeFixture(data: .initial)
        let flow = fixture.flow
        let first = try #require(flow.session)
        flow.recordClear()
        flow.handle(.nextDifficulty(.normal))
        #expect(flow.session === first, "鍵が付いているので始めない")
        #expect(flow.clearLockedDifficulty == .normal)
        #expect(flow.showsClearLockedGuide)
        flow.handle(.lockedGuideParents)
        #expect(flow.isShowingParentalGate)
        #expect(flow.path == [.game], "確認はクリアのダイアログの上に出す")
        flow.parentalGatePassed()
        #expect(flow.path == [.parents])
        await fixture.purchase()
        #expect(flow.path == [.game])
        let session = try #require(flow.session)
        #expect(session !== first)
        #expect(session.course == .animals)
        #expect(session.difficulty == .normal)
        #expect(!flow.showsClearLockedGuide)
        #expect(flow.clearLockedDifficulty == nil)
    }

    /// クリアの鍵の案内から出した確認をやめても、ホームに戻る
    @Test
    func cancellingGateFromClearGoesHome() {
        let flow = makeFixture(data: .initial).flow
        flow.recordClear()
        flow.handle(.nextDifficulty(.normal))
        flow.handle(.lockedGuideParents)
        flow.cancelParentalGate()
        #expect(flow.path.isEmpty)
        #expect(!flow.isShowingParentalGate)
        #expect(flow.parentsEntry == nil)
    }

    /// クリアの「もっと むずかしいのは おうちの方へ」は、確認を通ったらおうちの方への画面にする。
    /// 自動で購入はせず、購入してもゲームは始めない（押した難易度が無い）
    @Test
    func clearParentsGuideOpensParentsWithoutStarting() async throws {
        let fixture = makeFixture(data: .initial)
        let flow = fixture.flow
        let first = try #require(flow.session)
        flow.recordClear()
        flow.handle(.parents)
        #expect(flow.isShowingParentalGate)
        #expect(flow.parentsEntry == .clearGuide)
        #expect(flow.path == [.game], "確認を通るまでは、おうちの方への画面を出さない")
        flow.parentalGatePassed()
        #expect(flow.path == [.parents])
        let model = fixture.parentsModel()
        #expect(model.message == nil, "開いただけでは購入しない")
        #expect(!flow.hasPass)
        model.request(.purchase)
        await model.runPendingAction()
        #expect(model.message == .purchased)
        #expect(flow.hasPass)
        #expect(flow.path == [.parents], "画面に残って購入できた文を出す")
        #expect(flow.session === first)
    }

    // MARK: - 購入以外で権利が付いたとき

    /// 鍵から来ておうちの方への画面で復元しても、ゲームは始めない（復元の結果の文を読めるよう、画面に残す）
    @Test
    func restoreFromLockedDoesNotStart() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        fixture.backend.restorableEntitlement = true
        try openGateFromCourse(flow, course: .hiragana, difficulty: .normal)
        flow.parentalGatePassed()
        let model = fixture.parentsModel()
        model.request(.restore)
        await model.runPendingAction()
        #expect(model.message == .restored)
        #expect(flow.hasPass)
        #expect(flow.path == [.parents])
        #expect(flow.session == nil)
    }

    /// 承認待ちのあと、画面を開いたまま承認されても、ゲームは始めない（購入できた文を出して画面に残す）
    @Test
    func approvalFromLockedDoesNotStart() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        await flow.passStore.start()
        fixture.backend.nextPurchaseResult = .pending
        try openGateFromCourse(flow, course: .animals, difficulty: .hard)
        flow.parentalGatePassed()
        let model = await fixture.purchase()
        #expect(model.visibleMessage == .pending)
        fixture.backend.entitled = true
        fixture.backend.sendTransactionUpdate()
        try #require(await waitUntil { flow.hasPass })
        #expect(flow.path == [.parents])
        #expect(flow.session == nil)
        flow.passStore.stop()
    }

    // MARK: - 購入と返金で変わる表示

    /// 購入後は、コース選択の鍵と案内・スタンプちょうのパス専用の枠の鍵が消え、その変化が画面に伝わる
    @Test
    func purchaseRemovesLocks() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        #expect(CourseSelection.options(hasPass: flow.hasPass).contains { $0.isLocked })
        #expect(flow.stampBookLayout.pass.allSatisfy { $0.slot == .locked })
        try openGateFromCourse(flow, course: .hiragana, difficulty: .normal)
        flow.parentalGatePassed()
        await confirmation("鍵の表示が変わったと画面に伝わる") { changed in
            withObservationTracking {
                _ = flow.stampBookLayout
            } onChange: {
                changed()
            }
            await fixture.purchase()
        }
        #expect(!CourseSelection.options(hasPass: flow.hasPass).contains { $0.isLocked })
        #expect(flow.stampBookLayout.pass.allSatisfy { $0.slot == .empty })
        // ホームに戻ってコース選択を開き直すと、鍵の付いていたものもすぐ始まり、案内は出ない
        flow.goHome()
        flow.chooseCourse(.animals)
        #expect(flow.selectDifficulty(.hard) == .start(GameChoice(course: .animals, difficulty: .hard)))
    }

    /// コース選択とクリアの案内は、出したままパスが付いたら消える
    @Test
    func guidesHideWhenPassArrives() async throws {
        let fixture = makeFixture(data: .initial)
        let flow = fixture.flow
        flow.recordClear()
        flow.handle(.nextDifficulty(.normal))
        try #require(flow.showsClearLockedGuide)
        await flow.passStore.start()
        fixture.backend.entitled = true
        fixture.backend.sendTransactionUpdate()
        try #require(await waitUntil { flow.hasPass })
        #expect(!flow.showsClearLockedGuide)
        flow.goHome()
        flow.chooseCourse(.hiragana)
        #expect(flow.courseSelection?.showsLockedGuide(hasPass: flow.hasPass) == false)
        flow.passStore.stop()
    }

    /// 返金されたら鍵が戻り、ホームの「あそぶ」が前回の鍵の付いた難易度なら、そのコースのやさしいに落ちる（変化が画面に伝わる）
    @Test
    func refundRelocksAndResumeFallsBack() async throws {
        // パスの権利は StoreKit で確かめるまで端末内のキャッシュなので、キャッシュも持たせる
        let data = AppData(hasPassCache: true, lastCourse: .hiragana, lastDifficulty: .hard, hasClearedOnce: true)
        let fixture = makeFixture(data: data, entitled: true)
        let flow = fixture.flow
        await flow.passStore.start()
        try #require(flow.hasPass)
        #expect(flow.resumeChoice == GameChoice(course: .hiragana, difficulty: .hard))
        try await confirmation("「あそぶ」の表示が変わったと画面に伝わる") { changed in
            withObservationTracking {
                _ = flow.resumeChoice
            } onChange: {
                changed()
            }
            fixture.backend.entitled = false
            fixture.backend.sendTransactionUpdate()
            try #require(await waitUntil { !flow.hasPass })
        }
        #expect(flow.resumeChoice == GameChoice(course: .hiragana, difficulty: .easy))
        #expect(CourseSelection.options(hasPass: flow.hasPass).filter(\.isLocked).map(\.difficulty) == [.normal, .hard])
        #expect(flow.stampBookLayout.pass.allSatisfy { $0.slot == .locked })
        #expect(!fixture.store.data.hasPassCache)
        flow.passStore.stop()
    }
}
