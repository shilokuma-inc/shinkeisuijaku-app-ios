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
}
