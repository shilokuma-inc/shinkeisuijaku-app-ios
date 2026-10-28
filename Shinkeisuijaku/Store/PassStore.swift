//
//  PassStore.swift
//  Shinkeisuijaku
//
//  「ぜんぶ遊べるパス」（非消耗型の買い切り）のストア。読み込み・購入・復元・権利の確認。
//  権利の正は StoreKit の `Transaction.currentEntitlements`。端末内の値（`AppData.hasPassCache`）は起動直後の表示を早くするためだけに使う。
//  StoreKit との受け渡しは `PassStoreBackend` の後ろに置き、テスト・UI テスト・撮影モードでは擬似の実装に差し替える。
//

import Foundation
import Observation

/// パスのプロダクト ID（App Store Connect に登録する値。一度出したら変えない）
enum PassProduct {
    static let id = "jp.shilokuma.Shinkeisuijaku.pass"
}

/// 購入を試した結果（StoreKit の `Product.PurchaseResult` と検証の結果を、画面で扱う形にしたもの）
enum PassPurchaseResult: Equatable, Sendable {
    /// 買えた（検証も通った）
    case purchased
    /// 承認待ち（「承認と購入のリクエスト」など。あとで `Transaction.updates` に届く）
    case pending
    /// やめた
    case cancelled
    /// 買えたが検証に失敗した（権利は付けない）
    case unverified
    /// 失敗した（通信できない・商品が読めない など）
    case failed
    /// ほかの購入・復元の途中なので、何もしなかった
    case busy
}

/// 復元を試した結果
enum PassRestoreResult: Equatable, Sendable {
    /// 権利が戻った
    case restored
    /// 同期は終わったが、パスの購入が見つからなかった
    case notFound
    /// 失敗した（サインインをやめた・通信できない など）
    case failed
    /// ほかの購入・復元の途中なので、何もしなかった
    case busy
}

/// StoreKit との受け渡し
@MainActor
protocol PassStoreBackend: AnyObject {
    /// パスの値段の表示（例: ¥100）。読めなければ nil
    func loadDisplayPrice() async -> String?
    /// パスを買う
    func purchase() async -> PassPurchaseResult
    /// 今パスの権利があるか（返金されたものは含まない）
    func hasEntitlement() async -> Bool
    /// App Store と同期して購入を復元する
    func sync() async -> Bool
    /// 取引の変化（ほかの端末での購入・承認待ちの完了・返金）を待つ。変化があるたびに戻る
    func transactionUpdates() -> AsyncStream<Void>
}

/// パスのストア。画面はこの値を見て、鍵・値段・購入のボタンを出す。
/// アプリと同じ寿命で 1 つだけ作る（取引の変化の購読は `stop()` で止まる。`[weak self]` なので循環参照はしない）
@Observable
final class PassStore {
    /// パスの権利があるか。起動直後は端末内のキャッシュ、権利を確かめた後は StoreKit の値
    private(set) var hasPass: Bool
    /// 値段の表示（StoreKit の `displayPrice`）。読めるまでは nil
    private(set) var displayPrice: String?
    /// 値段を読み終えたのに読めなかったか（通信できない など）。次に読み直し始めたら false に戻す（読み込み中と見分ける）。
    /// 読み直しは、前面に戻ったときの確認（`refreshEntitlement()`）と、おうちの方への画面を開いたときに行う
    private(set) var priceLoadFailed = false
    /// 購入・復元の途中か（ボタンを押せなくする）
    private(set) var isBusy = false

    @ObservationIgnored private let backend: any PassStoreBackend
    @ObservationIgnored private let dataStore: any AppDataStore
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    /// 値段を読み直している途中の処理（重ねて読まないため。`stop()` で止める）
    @ObservationIgnored private var priceTask: Task<Void, Never>?
    /// 権利の確認を読み始めるたびに進める番号
    @ObservationIgnored private var latestCheck = 0
    /// 権利に使った確認の番号。これより前に読み始めた確認の結果は古いので捨てる（購入で権利を付けたら、それまでの確認をすべて古くする）
    @ObservationIgnored private var appliedCheck = 0

    init(backend: any PassStoreBackend, dataStore: any AppDataStore) {
        self.backend = backend
        self.dataStore = dataStore
        hasPass = dataStore.load().hasPassCache
    }

    /// 取引の変化の購読を始め、値段と権利を読む（起動時に 1 回呼ぶ）。値段は待たずに読み始め、権利を確かめたら戻る
    func start() async {
        startObservingTransactions()
        await refreshEntitlement()
    }

    /// 取引の変化の購読と、値段の読み直しを止める（ストアを捨てるとき）
    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        priceTask?.cancel()
        priceTask = nil
    }

    /// StoreKit で権利を確かめ直し、端末内のキャッシュも合わせる（起動時と前面に戻ったとき）。
    /// 値段がまだ無ければ読み直しも始めるが、その終わり（通信）は待たない
    func refreshEntitlement() async {
        reloadPriceIfMissing()
        await checkEntitlement()
    }

    /// 値段がまだ無ければ（起動時に読めなかったとき）、読み直しを始める。読み終わりは待たない（読めたら `displayPrice` が変わる）。
    /// 読み直している途中なら、重ねて読まない
    func reloadPriceIfMissing() {
        guard displayPrice == nil, priceTask == nil else {
            return
        }
        priceLoadFailed = false
        priceTask = Task { [weak self] in
            guard let backend = self?.backend else {
                return
            }
            let price = await backend.loadDisplayPrice()
            // stop() の後に読み終わっても、値段は変えない（読めなかったとき（nil）は、次に呼ばれたときに読み直す）
            guard let self, !Task.isCancelled else {
                return
            }
            priceTask = nil
            if displayPrice == nil {
                displayPrice = price
            }
            priceLoadFailed = displayPrice == nil
        }
    }

    /// StoreKit で権利だけを確かめ、端末内のキャッシュも合わせる（復元と取引の変化。値段の読み込みは待たない）
    private func checkEntitlement() async {
        latestCheck += 1
        let check = latestCheck
        let entitled = await backend.hasEntitlement()
        // 待っているあいだに、購入やあとから読み始めた確認で権利が決まっていたら、この結果は古いので使わない
        if check > appliedCheck {
            appliedCheck = check
            setHasPass(entitled)
        }
    }

    /// パスを買う。買えたら権利を付ける（承認待ちは、あとで取引の変化として届く）
    @discardableResult
    func purchase() async -> PassPurchaseResult {
        guard !isBusy else {
            return .busy
        }
        isBusy = true
        defer { isBusy = false }
        let result = await backend.purchase()
        if result == .purchased {
            appliedCheck = latestCheck
            setHasPass(true)
        }
        return result
    }

    /// 購入を復元する
    @discardableResult
    func restore() async -> PassRestoreResult {
        guard !isBusy else {
            return .busy
        }
        isBusy = true
        defer { isBusy = false }
        guard await backend.sync() else {
            return .failed
        }
        // 値段の読み込み（通信）を待つと、そのあいだ isBusy が残ってボタンを押せないので、権利だけを確かめる
        await checkEntitlement()
        return hasPass ? .restored : .notFound
    }

    private func startObservingTransactions() {
        guard updatesTask == nil else {
            return
        }
        let updates = backend.transactionUpdates()
        updatesTask = Task { [weak self] in
            for await _ in updates {
                // stop() の後に、溜まっていた変化が届いても権利を変えない（cancel されてもストリームは溜まった分を先に返す）
                guard let self, !Task.isCancelled else {
                    return
                }
                await self.checkEntitlement()
            }
        }
    }

    /// 権利を変え、端末内のキャッシュも合わせる（変わったときだけ保存する）
    private func setHasPass(_ value: Bool) {
        hasPass = value
        var data = dataStore.load()
        guard data.hasPassCache != value else {
            return
        }
        data.hasPassCache = value
        dataStore.save(data)
    }
}

/// 擬似のストア（Unit テスト・UI テスト・撮影モード用。StoreKit を使わない）。
/// App Store の撮影（`Tools/capture_screenshots.sh`）でも使うので Release にも入るが、一般の利用者は切り替えの起動引数を渡せない
@MainActor
final class FakePassStoreBackend: PassStoreBackend {
    var displayPrice: String? = "¥100"
    var entitled: Bool
    /// 次の購入の結果
    var nextPurchaseResult: PassPurchaseResult = .purchased
    /// 復元で見つかる購入があるか
    var restorableEntitlement = false
    /// 復元の同期が成功するか（サインインをやめた・通信できないときは false）
    var syncSucceeds = true
    private var continuation: AsyncStream<Void>.Continuation?
    /// 権利の確認を止めておくか（テストで、確認と購入が重なる順番を再現するため）
    var holdsEntitlementChecks = false
    /// 止めている権利の確認の数
    var heldEntitlementChecks: Int {
        heldChecks.count
    }
    private var heldChecks: [CheckedContinuation<Void, Never>] = []
    /// 値段の読み込みを止めておくか（テストで、値段の読み込み（通信）が終わらないあいだを再現するため）
    var holdsPriceLoads = false
    /// 止めている値段の読み込みの数
    var heldPriceLoadCount: Int {
        heldPriceLoads.count
    }
    private var heldPriceLoads: [CheckedContinuation<Void, Never>] = []
    /// 読み終わった値段の読み込みの数
    private(set) var finishedPriceLoadCount = 0
    /// 購入を止めておくか（テストで、購入中の二重押しを再現するため）
    var holdsPurchase = false
    private var heldPurchase: CheckedContinuation<Void, Never>?

    init(entitled: Bool = false) {
        self.entitled = entitled
    }

    func loadDisplayPrice() async -> String? {
        if holdsPriceLoads {
            await withCheckedContinuation { heldPriceLoads.append($0) }
        }
        finishedPriceLoadCount += 1
        return displayPrice
    }

    /// 止めている値段の読み込みを進める
    func releasePriceLoads() {
        let loads = heldPriceLoads
        heldPriceLoads = []
        loads.forEach { $0.resume() }
    }

    func purchase() async -> PassPurchaseResult {
        if holdsPurchase {
            await withCheckedContinuation { heldPurchase = $0 }
        }
        if nextPurchaseResult == .purchased {
            entitled = true
        }
        return nextPurchaseResult
    }

    func hasEntitlement() async -> Bool {
        // 確認を読み始めた時点の値を返す（読み終わるのが遅れても、そのあいだの変化は見ない）
        let value = entitled
        if holdsEntitlementChecks {
            await withCheckedContinuation { heldChecks.append($0) }
        }
        return value
    }

    /// 止めている権利の確認を進める
    func releaseEntitlementChecks() {
        let checks = heldChecks
        heldChecks = []
        checks.forEach { $0.resume() }
    }

    /// 止めている権利の確認のうち、最後に読み始めたものだけを進める
    func releaseLatestEntitlementCheck() {
        heldChecks.popLast()?.resume()
    }

    /// 止めている購入を進める
    func releasePurchase() {
        heldPurchase?.resume()
        heldPurchase = nil
    }

    func sync() async -> Bool {
        guard syncSucceeds else {
            return false
        }
        if restorableEntitlement {
            entitled = true
        }
        return true
    }

    func transactionUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    /// 取引の変化を起こす（承認待ちが通った・返金された などをテストで再現する）
    func sendTransactionUpdate() {
        continuation?.yield()
    }
}

/// 起動のしかたに合わせてストアを選ぶ
enum PassStoreFactory {
    /// Unit テストのホスト・UI テスト・撮影モードでは擬似のストア、それ以外は StoreKit
    static func makeBackend(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> any PassStoreBackend {
        let isUnitTestHost = environment["XCTestConfigurationFilePath"] != nil
        if isUnitTestHost || arguments.contains(AppDataStoreFactory.uiTestingArgument) || arguments.contains(ScreenshotDemo.argument) {
            return FakePassStoreBackend()
        }
        return StoreKitPassBackend()
    }
}
