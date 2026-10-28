//
//  PassStoreTests.swift
//  ShinkeisuijakuTests
//
//  パスのストアの決まり（権利の正は StoreKit・キャッシュの合わせ方・購入と復元の結果）を、擬似のストアで確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

@Suite(.timeLimit(.minutes(1)))
struct PassStoreTests {
    /// テストで使うストアと、その後ろの擬似のストア・保存
    private struct Fixture {
        let store: PassStore
        let backend: FakePassStoreBackend
        let data: InMemoryAppDataStore
    }

    private func makeStore(entitled: Bool = false, cache: Bool = false) -> Fixture {
        let backend = FakePassStoreBackend(entitled: entitled)
        let data = InMemoryAppDataStore(data: AppData(hasPassCache: cache))
        return Fixture(store: PassStore(backend: backend, dataStore: data), backend: backend, data: data)
    }

    /// 取引の変化が画面の値に届くまで、ほかの処理に順番を譲って待つ（時間では待たない）
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1_000 where !condition() {
            await Task.yield()
        }
    }

    /// 起動直後は端末内のキャッシュで表示し、StoreKit で確かめたら StoreKit の値に合わせる（キャッシュも直す）
    @Test
    func startUsesCacheThenStoreKit() async {
        let fixture = makeStore(entitled: false, cache: true)
        let store = fixture.store
        let data = fixture.data
        #expect(store.hasPass, "起動直後はキャッシュ")
        await store.start()
        #expect(!store.hasPass, "権利の正は StoreKit")
        #expect(!data.data.hasPassCache)
        // 値段は権利の確認を待たせないよう、待たずに読み始める
        await waitUntil { store.displayPrice != nil }
        #expect(store.displayPrice == "¥100")
        store.stop()
    }

    /// 買えたら権利を付けてキャッシュも保存する
    @Test
    func purchaseGrantsThePass() async {
        let fixture = makeStore()
        let store = fixture.store
        let data = fixture.data
        await store.start()
        #expect(await store.purchase() == .purchased)
        #expect(store.hasPass)
        #expect(data.data.hasPassCache)
        store.stop()
    }

    /// 承認待ち・やめた・検証の失敗・失敗では、権利を付けない
    @Test
    func otherPurchaseResultsDoNotGrantThePass() async {
        for result in [PassPurchaseResult.pending, .cancelled, .unverified, .failed] {
            let fixture = makeStore()
            let store = fixture.store
            let backend = fixture.backend
            let data = fixture.data
            backend.nextPurchaseResult = result
            await store.start()
            #expect(await store.purchase() == result)
            #expect(!store.hasPass, "\(result)")
            #expect(!data.data.hasPassCache)
            store.stop()
        }
    }

    /// 承認待ちのあとで承認されたら、取引の変化で権利が付く
    @Test
    func approvedPendingPurchaseArrivesAsUpdate() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.nextPurchaseResult = .pending
        await store.start()
        await store.purchase()
        backend.entitled = true
        backend.sendTransactionUpdate()
        await waitUntil { store.hasPass }
        #expect(store.hasPass)
        store.stop()
    }

    /// 返金で権利が消えたら、取引の変化で鍵が戻り、キャッシュも消える
    @Test
    func refundRemovesThePass() async {
        let fixture = makeStore(entitled: true, cache: true)
        let store = fixture.store
        let backend = fixture.backend
        let data = fixture.data
        await store.start()
        #expect(store.hasPass)
        backend.entitled = false
        backend.sendTransactionUpdate()
        await waitUntil { !store.hasPass }
        #expect(!store.hasPass)
        #expect(!data.data.hasPassCache)
        store.stop()
    }

    /// 復元: 見つかれば権利が戻る・見つからなければ notFound・同期に失敗したら failed
    @Test
    func restoreResults() async {
        let foundFixture = makeStore()
        let found = foundFixture.store
        let foundBackend = foundFixture.backend
        foundBackend.restorableEntitlement = true
        #expect(await found.restore() == .restored)
        #expect(found.hasPass)

        let missingFixture = makeStore()
        let missing = missingFixture.store
        #expect(await missing.restore() == .notFound)
        #expect(!missing.hasPass)

        let failingFixture = makeStore()
        let failing = failingFixture.store
        let failingBackend = failingFixture.backend
        failingBackend.syncSucceeds = false
        #expect(await failing.restore() == .failed)
    }

    /// 前面に戻ったときに確かめ直すと、ほかの端末で買った権利も付く
    @Test
    func refreshPicksUpEntitlementFromElsewhere() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        await store.start()
        backend.entitled = true
        await store.refreshEntitlement()
        #expect(store.hasPass)
        store.stop()
    }

    /// Unit テストのホスト・UI テスト・撮影モードでは StoreKit を使わない
    @Test
    func factoryUsesFakeOutsideNormalLaunch() {
        #expect(PassStoreFactory.makeBackend(arguments: [], environment: ["XCTestConfigurationFilePath": "/tmp/x"]) is FakePassStoreBackend)
        #expect(PassStoreFactory.makeBackend(arguments: ["-uiTesting"], environment: [:]) is FakePassStoreBackend)
        #expect(PassStoreFactory.makeBackend(arguments: ["-screenshot-demo"], environment: [:]) is FakePassStoreBackend)
        #expect(PassStoreFactory.makeBackend(arguments: [], environment: [:]) is StoreKitPassBackend)
    }

    /// 購入より前に読み始めた権利の確認が後から終わっても、購入の結果を古い値で上書きしない
    @Test
    func staleEntitlementCheckDoesNotUndoPurchase() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        await store.start()
        backend.holdsEntitlementChecks = true
        let refreshing = Task { await store.refreshEntitlement() }
        await waitUntil { backend.heldEntitlementChecks == 1 }
        #expect(await store.purchase() == .purchased)
        #expect(store.hasPass)
        backend.releaseEntitlementChecks()
        await refreshing.value
        #expect(store.hasPass, "古い確認の結果（権利なし）で鍵を戻さない")
        #expect(fixture.data.data.hasPassCache)
        store.stop()
    }

    /// あとから読み始めた確認（承認待ちが承認された など）が先に終わったら、前に読み始めた古い確認の結果で戻さない
    @Test
    func olderEntitlementCheckFinishingLastIsIgnored() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        await store.start()
        backend.holdsEntitlementChecks = true
        let older = Task { await store.refreshEntitlement() }
        await waitUntil { backend.heldEntitlementChecks == 1 }
        backend.entitled = true
        let newer = Task { await store.refreshEntitlement() }
        await waitUntil { backend.heldEntitlementChecks == 2 }
        backend.releaseLatestEntitlementCheck()
        await newer.value
        #expect(store.hasPass)
        backend.releaseEntitlementChecks()
        await older.value
        #expect(store.hasPass, "前に読み始めた確認（権利なし）で鍵を戻さない")
        #expect(fixture.data.data.hasPassCache)
        store.stop()
    }

    /// 購入の途中にもう一度押しても、何もせずに busy を返す（復元も同じ）
    @Test
    func secondTapWhileBusyIsIgnored() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.holdsPurchase = true
        let purchasing = Task { await store.purchase() }
        await waitUntil { store.isBusy }
        #expect(await store.purchase() == .busy)
        #expect(await store.restore() == .busy)
        backend.releasePurchase()
        #expect(await purchasing.value == .purchased)
        #expect(!store.isBusy)
    }

    /// 購読を止めた後は、取引の変化が届いても権利を変えない
    @Test
    func stopEndsTransactionUpdates() async {
        let fixture = makeStore(entitled: true, cache: true)
        let store = fixture.store
        let backend = fixture.backend
        await store.start()
        store.stop()
        backend.entitled = false
        backend.sendTransactionUpdate()
        for _ in 0..<100 {
            await Task.yield()
        }
        #expect(store.hasPass)
    }

    /// 起動時に値段を読めなかったら、権利を確かめ直すとき（と画面から頼まれたとき）に読み直す
    @Test
    func priceIsReloadedWhenMissing() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.displayPrice = nil
        await store.start()
        await waitUntil { backend.finishedPriceLoadCount == 1 }
        #expect(store.displayPrice == nil)
        backend.displayPrice = "¥100"
        backend.holdsPriceLoads = true
        await store.refreshEntitlement()
        await waitUntil { backend.heldPriceLoadCount == 1 }
        // 読み直している途中に重ねて頼んでも、読み込みは 1 つだけ
        store.reloadPriceIfMissing()
        for _ in 0..<100 {
            await Task.yield()
        }
        #expect(backend.heldPriceLoadCount == 1)
        backend.releasePriceLoads()
        await waitUntil { store.displayPrice != nil }
        #expect(store.displayPrice == "¥100")
        store.stop()
    }

    /// 値段の読み込み（通信）が終わらなくても、復元は権利を確かめたら終わり、ボタンを押せるように戻す（PR #32 の申し送り）
    @Test
    func restoreDoesNotWaitForPrice() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.displayPrice = nil
        backend.holdsPriceLoads = true
        backend.restorableEntitlement = true
        await store.start()
        #expect(await store.restore() == .restored)
        #expect(!store.isBusy)
        #expect(store.hasPass)
        #expect(store.displayPrice == nil, "値段はまだ読み込み中")
        backend.releasePriceLoads()
        store.stop()
    }

    /// 取引の変化で権利を確かめるときも、値段の読み込みを待たない
    @Test
    func transactionUpdateDoesNotWaitForPrice() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.displayPrice = nil
        backend.holdsPriceLoads = true
        await store.start()
        backend.entitled = true
        backend.sendTransactionUpdate()
        await waitUntil { store.hasPass }
        #expect(store.hasPass)
        #expect(backend.heldPriceLoadCount == 1, "読み込みは起動時の 1 つだけで、取引の変化では増やさない")
        backend.releasePriceLoads()
        store.stop()
    }

    /// 止めた後に値段を読み終わっても、値段は変えない
    @Test
    func stopCancelsPriceReload() async {
        let fixture = makeStore()
        let store = fixture.store
        let backend = fixture.backend
        backend.holdsPriceLoads = true
        await store.start()
        await waitUntil { backend.heldPriceLoadCount == 1 }
        store.stop()
        backend.releasePriceLoads()
        for _ in 0..<100 {
            await Task.yield()
        }
        #expect(store.displayPrice == nil)
    }
}
