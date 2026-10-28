//
//  ParentsModelTests.swift
//  ShinkeisuijakuTests
//
//  おうちの方への画面の決まり（購入・復元の結果ごとの文・購入のボタンを出すか・押せるか・外部のリンク）を、擬似のストアで確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

@Suite(.timeLimit(.minutes(1)))
struct ParentsModelTests {
    /// テストで使う画面の状態と、その後ろの擬似のストア
    private struct Fixture {
        let model: ParentsModel
        let backend: FakePassStoreBackend
    }

    /// 起動時の権利の確認と値段の読み込みが終わった状態で作る
    private func makeModel(entitled: Bool = false) async throws -> Fixture {
        let backend = FakePassStoreBackend(entitled: entitled)
        let data = InMemoryAppDataStore(data: AppData(hasPassCache: entitled))
        let passStore = PassStore(backend: backend, dataStore: data)
        await passStore.start()
        // 値段は権利の確認を待たせないよう、待たずに読み始めるので、読み終わるまで待つ
        try #require(await waitUntil { passStore.displayPrice != nil })
        return Fixture(model: ParentsModel(passStore: passStore), backend: backend)
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

    // MARK: - 結果の文（純粋な関数）

    /// 購入の結果ごとの文。キャンセルは何も出さない
    @Test
    func purchaseResultMessages() {
        #expect(ParentsMessage(purchase: .purchased) == .purchased)
        #expect(ParentsMessage(purchase: .pending) == .pending)
        #expect(ParentsMessage(purchase: .cancelled) == nil)
        #expect(ParentsMessage(purchase: .unverified) == .unverified)
        #expect(ParentsMessage(purchase: .failed) == .purchaseFailed)
        #expect(ParentsMessage(purchase: .busy) == .busy)
    }

    /// 復元の結果ごとの文
    @Test
    func restoreResultMessages() {
        #expect(ParentsMessage(restore: .restored) == .restored)
        #expect(ParentsMessage(restore: .notFound) == .restoreNotFound)
        #expect(ParentsMessage(restore: .failed) == .restoreFailed)
        #expect(ParentsMessage(restore: .busy) == .busy)
    }

    /// 文はどれも空でなく、互いに違う。うまくいったものだけが問題ではない
    @Test
    func messagesAreDistinct() {
        let all: [ParentsMessage] = [.purchased, .pending, .unverified, .purchaseFailed, .busy, .restored, .restoreNotFound, .restoreFailed]
        #expect(all.allSatisfy { !$0.text.isEmpty })
        #expect(Set(all.map(\.text)).count == all.count)
        #expect(all.filter { !$0.isProblem } == [.purchased, .pending, .restored])
    }

    // MARK: - パスの欄（純粋な関数）

    /// 購入前は「購入する」と「購入を復元」を出し、値段が読めていれば押せる
    @Test
    func beforePurchaseShowsBothButtons() {
        let status = ParentsPassStatus(hasPass: false, displayPrice: "¥100", isBusy: false)
        #expect(status.showsPurchaseButton)
        #expect(status.canPurchase)
        #expect(status.showsRestoreButton)
        #expect(status.canRestore)
        #expect(status.priceText == "¥100")
    }

    /// 購入済みなら、購入のボタンも復元のボタンも出さない
    @Test
    func purchasedHidesButtons() {
        let status = ParentsPassStatus(hasPass: true, displayPrice: "¥100", isBusy: false)
        #expect(!status.showsPurchaseButton)
        #expect(!status.canPurchase)
        #expect(!status.showsRestoreButton)
        #expect(!status.canRestore)
    }

    /// 値段が読めるまでは読み込み中の表示にし、値段を見せる前には買わせない（復元はできる）
    @Test
    func missingPriceBlocksPurchaseOnly() {
        let status = ParentsPassStatus(hasPass: false, displayPrice: nil, isBusy: false)
        #expect(status.priceText == String(localized: "読み込み中…"))
        #expect(status.showsPurchaseButton)
        #expect(!status.canPurchase)
        #expect(status.canRestore)
    }

    /// 処理中は、購入も復元も押せない
    @Test
    func busyDisablesButtons() {
        let status = ParentsPassStatus(hasPass: false, displayPrice: "¥100", isBusy: true)
        #expect(status.showsPurchaseButton)
        #expect(!status.canPurchase)
        #expect(!status.canRestore)
    }

    // MARK: - 擬似のストアでの購入と復元

    /// 買えたら購入済みになり、購入のボタンを消して完了の文を出す
    @Test
    func purchaseSucceeds() async throws {
        let fixture = try await makeModel()
        let model = fixture.model
        #expect(model.status.showsPurchaseButton)
        model.request(.purchase)
        #expect(model.status.isBusy, "押してから処理が始まるまでも押せない")
        await model.runPendingAction()
        #expect(model.message == .purchased)
        #expect(model.status.hasPass)
        #expect(!model.status.showsPurchaseButton)
        #expect(model.pendingAction == nil)
        model.passStore.stop()
    }

    /// 買えなかった購入の結果と、そのときに出す文
    nonisolated private static let unsuccessfulPurchases: [(PassPurchaseResult, ParentsMessage?)] = [
        (.pending, .pending),
        (.unverified, .unverified),
        (.failed, .purchaseFailed),
        (.cancelled, nil)
    ]

    /// 承認待ち・検証の失敗・失敗では購入済みにならず、それぞれの文を出す。キャンセルは何も出さない
    @Test(arguments: unsuccessfulPurchases)
    func purchaseOtherResults(result: PassPurchaseResult, expected: ParentsMessage?) async throws {
        let fixture = try await makeModel()
        let model = fixture.model
        fixture.backend.nextPurchaseResult = result
        model.request(.purchase)
        await model.runPendingAction()
        #expect(model.message == expected)
        #expect(!model.status.hasPass)
        #expect(model.status.showsPurchaseButton)
        #expect(model.status.canPurchase, "終わったら、もう一度押せる")
        model.passStore.stop()
    }

    /// キャンセルしたら、前の結果の文も消す
    @Test
    func cancelClearsPreviousMessage() async throws {
        let fixture = try await makeModel()
        let model = fixture.model
        fixture.backend.nextPurchaseResult = .failed
        model.request(.purchase)
        await model.runPendingAction()
        #expect(model.message == .purchaseFailed)
        fixture.backend.nextPurchaseResult = .cancelled
        model.request(.purchase)
        await model.runPendingAction()
        #expect(model.message == nil)
        model.passStore.stop()
    }

    /// 復元: 見つかれば購入済みになる・見つからない・同期に失敗した、のそれぞれの文を出す
    @Test
    func restoreResults() async throws {
        let found = try await makeModel()
        found.backend.restorableEntitlement = true
        found.model.request(.restore)
        await found.model.runPendingAction()
        #expect(found.model.message == .restored)
        #expect(found.model.status.hasPass)
        #expect(!found.model.status.showsPurchaseButton)
        found.model.passStore.stop()

        let missing = try await makeModel()
        missing.model.request(.restore)
        await missing.model.runPendingAction()
        #expect(missing.model.message == .restoreNotFound)
        #expect(!missing.model.status.hasPass)
        missing.model.passStore.stop()

        let failing = try await makeModel()
        failing.backend.syncSucceeds = false
        failing.model.request(.restore)
        await failing.model.runPendingAction()
        #expect(failing.model.message == .restoreFailed)
        failing.model.passStore.stop()
    }

    /// 処理の途中にもう一度押しても、あとから押したものは進めない（購入中に復元を押しても 1 回だけ）
    @Test
    func secondRequestWhileRunningIsIgnored() async throws {
        let fixture = try await makeModel()
        let model = fixture.model
        let backend = fixture.backend
        backend.holdsPurchase = true
        model.request(.purchase)
        let running = Task { await model.runPendingAction() }
        try #require(await waitUntil { model.passStore.isBusy })
        model.request(.restore)
        #expect(model.pendingAction == .purchase)
        #expect(!model.status.canRestore)
        backend.releasePurchase()
        await running.value
        #expect(model.message == .purchased)
        #expect(model.pendingAction == nil)
        model.passStore.stop()
    }

    /// 押された処理が無ければ、進めても何もしない
    @Test
    func runWithoutRequestDoesNothing() async throws {
        let fixture = try await makeModel()
        await fixture.model.runPendingAction()
        #expect(fixture.model.message == nil)
        #expect(!fixture.model.status.hasPass)
        fixture.model.passStore.stop()
    }

    /// 購入済みで開いたら、購入のボタンを出さない
    @Test
    func openingWithPassShowsPurchased() async throws {
        let fixture = try await makeModel(entitled: true)
        #expect(fixture.model.status.hasPass)
        #expect(!fixture.model.status.showsPurchaseButton)
        fixture.model.passStore.stop()
    }

    /// 起動時に値段を読めなかったら、画面を開いたときに読み直す
    @Test
    func appearReloadsMissingPrice() async throws {
        let backend = FakePassStoreBackend()
        backend.displayPrice = nil
        let passStore = PassStore(backend: backend, dataStore: InMemoryAppDataStore(data: .initial))
        await passStore.start()
        try #require(await waitUntil { backend.finishedPriceLoadCount == 1 })
        let model = ParentsModel(passStore: passStore)
        #expect(!model.status.canPurchase)
        backend.displayPrice = "¥100"
        model.appear()
        #expect(await waitUntil { model.status.displayPrice == "¥100" })
        #expect(model.status.canPurchase)
        passStore.stop()
    }

    // MARK: - 外部のリンク

    /// リンクは https で、決めた場所を指す（App Store の掲載と同じ URL）
    @Test
    func linksPointToDecidedPages() {
        #expect(ParentsLinks.privacyPolicy.absoluteString == "https://shilokuma.jp/privacy/shinkeisuijaku/")
        #expect(ParentsLinks.contact.scheme == "https")
        #expect(ParentsLinks.contact.host == "docs.google.com")
        #expect(ParentsLinks.contact.path.hasSuffix("/viewform"))
    }
}
