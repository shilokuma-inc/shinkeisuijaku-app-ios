//
//  ParentsModel.swift
//  Shinkeisuijaku
//
//  おうちの方への画面（仕様書の「画面と遷移」「収益・課金」）で決めること。
//  パスの欄に何を出すか（値段・購入のボタン・復元のボタン・押せるか）と、購入・復元の結果ごとに保護者へ出す短い文を、
//  View から切り離した値の型と純粋な関数にして単体テストする。購入・復元を進めるのは `ParentsModel`（パスのストアを呼ぶ）。
//  保護者向けの画面なので、文は漢字を含む大人向けにする（CLAUDE.md の方針 4）。
//

import Foundation
import Observation

/// 購入・復元の結果として、パスの欄の下に出す保護者向けの短い文
enum ParentsMessage: Equatable, Sendable {
    /// 買えた
    case purchased
    /// 承認待ち（ファミリー共有の「承認と購入のリクエスト」など）
    case pending
    /// 買えたが検証に失敗した
    case unverified
    /// 購入に失敗した
    case purchaseFailed
    /// ほかの購入・復元の途中だった
    case busy
    /// 復元できた
    case restored
    /// 復元できる購入が見つからなかった
    case restoreNotFound
    /// 復元に失敗した
    case restoreFailed

    /// 購入の結果に出す文。やめたとき（キャンセル）は何も出さない
    init?(purchase result: PassPurchaseResult) {
        switch result {
        case .purchased: self = .purchased
        case .pending: self = .pending
        case .cancelled: return nil
        case .unverified: self = .unverified
        case .failed: self = .purchaseFailed
        case .busy: self = .busy
        }
    }

    /// 復元の結果に出す文
    init(restore result: PassRestoreResult) {
        switch result {
        case .restored: self = .restored
        case .notFound: self = .restoreNotFound
        case .failed: self = .restoreFailed
        case .busy: self = .busy
        }
    }

    /// 画面に出す文（VoiceOver でも読み上げる）
    var text: String {
        switch self {
        case .purchased:
            String(localized: "購入が完了しました。「ふつう」と「むずかしい」が遊べます。")
        case .pending:
            String(localized: "購入の承認を待っています。承認されると、自動で遊べるようになります。")
        case .unverified:
            String(localized: "購入を確認できませんでした。しばらくしてから「購入を復元」をお試しください。")
        case .purchaseFailed:
            String(localized: "購入できませんでした。通信の状態を確かめて、もう一度お試しください。")
        case .busy:
            String(localized: "ほかの処理の途中です。終わってから、もう一度お試しください。")
        case .restored:
            String(localized: "購入を復元しました。「ふつう」と「むずかしい」が遊べます。")
        case .restoreNotFound:
            String(localized: "復元できる購入が見つかりませんでした。購入したときと同じ Apple アカウントでサインインしているかご確認ください。")
        case .restoreFailed:
            String(localized: "復元できませんでした。通信の状態を確かめて、もう一度お試しください。")
        }
    }

    /// 権利の有無に合わせて出す文。
    /// 権利が付いたら、承認待ちは購入できた文に変え（画面を開いたまま承認された）、うまくいかなかった文は出さない。
    /// 権利が外れたら（返金・ほかの端末での変化）、うまくいった文（購入できた・復元できた）を出さない
    static func visible(_ message: ParentsMessage?, hasPass: Bool) -> ParentsMessage? {
        guard let message else {
            return nil
        }
        if hasPass {
            if message == .pending {
                return .purchased
            }
            return message.isProblem ? nil : message
        }
        return message == .purchased || message == .restored ? nil : message
    }

    /// うまくいかなかったことを伝える文か（文の前に付ける印を変える。色だけに頼らず、言葉でも伝わる文にしている）
    var isProblem: Bool {
        switch self {
        case .purchased, .pending, .restored: false
        case .unverified, .purchaseFailed, .busy, .restoreNotFound, .restoreFailed: true
        }
    }
}

/// パスの欄に出すもの（権利・値段・処理中かから決める）
struct ParentsPassStatus: Equatable, Sendable {
    /// パスの権利があるか
    let hasPass: Bool
    /// 値段の表示（StoreKit の `displayPrice`。読めるまでは nil）
    let displayPrice: String?
    /// 購入・復元の途中か（押してから処理が始まるまでを含む）
    let isBusy: Bool
    /// 値段を読み終えたのに読めなかったか（読み込み中とは別の表示にする）
    var priceLoadFailed = false

    /// 「購入する」を出すか（購入済みなら出さず、その旨を出す）
    var showsPurchaseButton: Bool {
        !hasPass
    }

    /// 「購入する」を押せるか。値段を見せる前には買わせない（値段が読めるまで・処理中は押せない）
    var canPurchase: Bool {
        showsPurchaseButton && displayPrice != nil && !isBusy
    }

    /// 「購入を復元」を出すか（購入済みなら、復元するものが無いので出さない）
    var showsRestoreButton: Bool {
        !hasPass
    }

    /// 「購入を復元」を押せるか（処理中は押せない。値段が読めなくても復元はできる）
    var canRestore: Bool {
        showsRestoreButton && !isBusy
    }

    /// 値段の欄に出す文字（読めるまでは読み込み中、読めなかったらその旨の表示。値段を直書きしない）
    var priceText: String {
        if let displayPrice {
            return displayPrice
        }
        return priceLoadFailed ? String(localized: "読み込めませんでした") : String(localized: "読み込み中…")
    }

    /// 値段を読めなかったときに、値段の下に出す説明（読めたとき・読み込み中は nil）。
    /// 値段は、この画面を開いたときと、アプリが前面に戻ったとき（`PassStore.refreshEntitlement()`）に読み直すので、両方を伝える
    var priceFailureNote: String? {
        guard displayPrice == nil, priceLoadFailed else {
            return nil
        }
        return String(localized: "通信できる状態で、この画面を開き直すか、ほかのアプリから戻ってくると、もう一度読み込みます。")
    }
}

/// おうちの方への画面で押せる処理
enum ParentsAction: Equatable, Sendable {
    /// 購入する
    case purchase
    /// 購入を復元
    case restore
}

/// おうちの方への画面の状態（パスの欄と、購入・復元の結果の文）。画面ごとに作り、画面を閉じたら捨てる
@Observable
final class ParentsModel {
    /// 最後の購入・復元の結果の文（出していないときは nil）
    private(set) var message: ParentsMessage?
    /// 押されて、まだ終わっていない処理。画面の `.task(id:)` がこれを見て進める（押してから処理が始まるまでも二重に押させない）
    private(set) var pendingAction: ParentsAction?

    @ObservationIgnored let passStore: PassStore
    /// 購入が終わったとき（`.purchased`）に呼ぶ。画面の流れが、押した難易度のゲームを始めるのに使う
    @ObservationIgnored private let onPurchased: () -> Void

    init(passStore: PassStore, onPurchased: @escaping () -> Void = {}) {
        self.passStore = passStore
        self.onPurchased = onPurchased
    }

    /// 画面に出す結果の文。画面を開いたまま権利が変わっても（承認された・ほかの端末で買われた・返金された）、
    /// 「購入済み」かどうかと食い違う文を残さない（承認されたら購入できた文に変わり、画面がそれを読み上げる）
    var visibleMessage: ParentsMessage? {
        ParentsMessage.visible(message, hasPass: passStore.hasPass)
    }

    /// パスの欄に出すもの
    var status: ParentsPassStatus {
        ParentsPassStatus(
            hasPass: passStore.hasPass,
            displayPrice: passStore.displayPrice,
            isBusy: passStore.isBusy || pendingAction != nil,
            priceLoadFailed: passStore.priceLoadFailed
        )
    }

    /// 画面を開いたとき。値段がまだ読めていなければ読み直す（待たない）
    func appear() {
        passStore.reloadPriceIfMissing()
    }

    /// ボタンを押したとき。処理の途中なら何もしない（二重に押しても 1 回だけ）
    func request(_ action: ParentsAction) {
        guard pendingAction == nil else {
            return
        }
        pendingAction = action
    }

    /// 押された処理を進め、結果の文を出す（画面の寿命の `.task(id:)` から呼ぶ）。押された処理が無ければ何もしない。
    /// 購入が終わったら、処理を終えてから `onPurchased` を呼ぶ（呼ばれた先で画面が変わっても、処理中のまま残らない）
    func runPendingAction() async {
        guard let action = pendingAction else {
            return
        }
        // 前の結果の文は、新しい処理を始めたら消す（やめたときに古い文が残らないように）
        message = nil
        var purchased = false
        switch action {
        case .purchase:
            let result = await passStore.purchase()
            purchased = result == .purchased
            message = ParentsMessage(purchase: result)
        case .restore:
            message = ParentsMessage(restore: await passStore.restore())
        }
        pendingAction = nil
        if purchased {
            onPurchased()
        }
    }
}
