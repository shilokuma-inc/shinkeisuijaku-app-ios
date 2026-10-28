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
}

/// 復元を試した結果
enum PassRestoreResult: Equatable, Sendable {
    /// 権利が戻った
    case restored
    /// 同期は終わったが、パスの購入が見つからなかった
    case notFound
    /// 失敗した（サインインをやめた・通信できない など）
    case failed
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

/// パスのストア。画面はこの値を見て、鍵・値段・購入のボタンを出す
@Observable
final class PassStore {
    /// パスの権利があるか。起動直後は端末内のキャッシュ、権利を確かめた後は StoreKit の値
    private(set) var hasPass: Bool
    /// 値段の表示（StoreKit の `displayPrice`）。読めるまでは nil
    private(set) var displayPrice: String?
    /// 購入・復元の途中か（ボタンを押せなくする）
    private(set) var isBusy = false

    @ObservationIgnored private let backend: any PassStoreBackend
    @ObservationIgnored private let dataStore: any AppDataStore
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(backend: any PassStoreBackend, dataStore: any AppDataStore) {
        self.backend = backend
        self.dataStore = dataStore
        hasPass = dataStore.load().hasPassCache
    }

    /// 取引の変化の購読を始め、値段と権利を読む（起動時に 1 回呼ぶ）
    func start() async {
        startObservingTransactions()
        displayPrice = await backend.loadDisplayPrice()
        await refreshEntitlement()
    }

    /// 取引の変化の購読を止める（ストアを捨てるとき）
    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    /// StoreKit で権利を確かめ直し、端末内のキャッシュも合わせる（起動時と前面に戻ったとき）
    func refreshEntitlement() async {
        setHasPass(await backend.hasEntitlement())
    }

    /// パスを買う。買えたら権利を付ける（承認待ちは、あとで取引の変化として届く）
    @discardableResult
    func purchase() async -> PassPurchaseResult {
        guard !isBusy else {
            return .failed
        }
        isBusy = true
        defer { isBusy = false }
        let result = await backend.purchase()
        if result == .purchased {
            setHasPass(true)
        }
        return result
    }

    /// 購入を復元する
    @discardableResult
    func restore() async -> PassRestoreResult {
        guard !isBusy else {
            return .failed
        }
        isBusy = true
        defer { isBusy = false }
        guard await backend.sync() else {
            return .failed
        }
        await refreshEntitlement()
        return hasPass ? .restored : .notFound
    }

    private func startObservingTransactions() {
        guard updatesTask == nil else {
            return
        }
        let updates = backend.transactionUpdates()
        updatesTask = Task { [weak self] in
            for await _ in updates {
                guard let self else {
                    return
                }
                await self.refreshEntitlement()
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

/// 擬似のストア（UI テスト・撮影モード用。StoreKit を使わない）
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

    init(entitled: Bool = false) {
        self.entitled = entitled
    }

    func loadDisplayPrice() async -> String? {
        displayPrice
    }

    func purchase() async -> PassPurchaseResult {
        if nextPurchaseResult == .purchased {
            entitled = true
        }
        return nextPurchaseResult
    }

    func hasEntitlement() async -> Bool {
        entitled
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
