//
//  ParentsView.swift
//  Shinkeisuijaku
//
//  おうちの方への画面（仕様書の「画面と遷移」「収益・課金」・引き継ぎブックの 10 ページ）。保護者の確認を通ったあとにだけ開く。
//  パスの内容と価格・「購入する」・「購入を復元」・方針の説明（広告なし・個人情報を集めない・データは端末の中だけ・通信しない）・
//  プライバシーポリシーとお問い合わせのリンク（ブラウザで開く）と、下に「ホームにもどる」。
//  引き継ぎブックに見本が無いので、面の色の箱・通常と主なボタン・文字のトークンだけで組む。保護者向けなので文は漢字を使う。
//  何を出すか・結果の文は `ParentsModel` が決め、この画面はそれを並べるだけ。
//

import SwiftUI

/// おうちの方への画面
struct ParentsView: View {
    /// 「ホームにもどる」を押したとき
    var onHome: () -> Void = {}

    @State private var model: ParentsModel
    @Environment(\.openURL) private var openURL

    init(passStore: PassStore, onHome: @escaping () -> Void = {}) {
        _model = State(initialValue: ParentsModel(passStore: passStore))
        self.onHome = onHome
    }

    var body: some View {
        // 画面に入らないとき（iPhone SE・文字を大きくしたとき）は、スクロールで全部見られる
        ScrollView {
            content
                .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        // 「ホームにもどる」はスクロールしても隠れないよう、下に固定する（スタンプちょうと同じ）
        .safeAreaInset(edge: .bottom, spacing: 0) {
            homeButton
        }
        .background(Palette.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("parents")
        .task {
            model.appear()
        }
        // 購入・復元は画面の寿命で進める（画面を閉じたら待つのをやめる。権利は取引の変化の購読で届く）
        .task(id: model.pendingAction) {
            await model.runPendingAction()
        }
        .onChange(of: model.visibleMessage) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message.text).post()
            }
        }
    }

    /// 見出し・パス・方針・リンク（上から順に並べる）
    private var content: some View {
        VStack(spacing: Metrics.parentsSectionSpacing) {
            Text("おうちの方へ")
                .appFont(Typography.dialogTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            passSection
            policySection
            linksSection
        }
        .padding(.horizontal, Metrics.screenHorizontalPadding)
        .padding(.vertical, Metrics.cardSpacing)
    }

    // MARK: - パス

    /// パスの内容・価格・購入と復元・結果の文
    private var passSection: some View {
        let status = model.status
        return ParentsSection(title: "ぜんぶ遊べるパス") {
            ParentsBullet("どうぶつ・ひらがなの 2 つのコースで、「ふつう」と「むずかしい」が遊べます。")
            ParentsBullet("パス専用のスタンプも集められます。")
            ParentsBullet("買い切りです。一度の購入で、追加の料金はかかりません。")
            Text("「やさしい」は、パスが無くても遊べます。")
                .appFont(Typography.note)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            priceRow(status)
            if status.showsPurchaseButton {
                Button {
                    model.request(.purchase)
                } label: {
                    actionLabel("購入する", isRunning: model.pendingAction == .purchase)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!status.canPurchase)
                .accessibilityIdentifier("parents.purchase")
            } else {
                purchasedNotice
            }
            if status.showsRestoreButton {
                Button {
                    model.request(.restore)
                } label: {
                    actionLabel("購入を復元", isRunning: model.pendingAction == .restore)
                        .appFont(Typography.button)
                        .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                }
                .buttonStyle(SurfaceButtonStyle())
                .disabled(!status.canRestore)
                .accessibilityIdentifier("parents.restore")
            }
            if let message = model.visibleMessage {
                messageView(message)
            }
        }
    }

    /// 価格（読めるまでは読み込み中の表示。値段は StoreKit の表示をそのまま出す）
    private func priceRow(_ status: ParentsPassStatus) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.cardSpacing) {
            Text("価格")
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
            Spacer(minLength: Metrics.cardSpacing)
            Text(verbatim: status.priceText)
                .appFont(status.displayPrice == nil ? Typography.body : Typography.pairCountNumber)
                .foregroundStyle(status.displayPrice == nil ? Palette.muted : Palette.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("価格 \(status.priceText)"))
        .accessibilityIdentifier("parents.price")
    }

    /// ボタンの文字。処理中は文字の左に回る印を出す
    private func actionLabel(_ title: LocalizedStringKey, isRunning: Bool) -> some View {
        HStack(spacing: Metrics.cardSpacing) {
            if isRunning {
                ProgressView()
                    .accessibilityHidden(true)
            }
            Text(title)
        }
    }

    /// 購入済みのとき、「購入する」の代わりに出す
    private var purchasedNotice: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.cardSpacing) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text("ぜんぶ遊べるパスは購入済みです")
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appFont(Typography.button)
        .padding(.horizontal, Metrics.parentsSectionPadding)
        .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("parents.purchased")
    }

    /// 購入・復元の結果の文。うまくいかなかったときは印を変える（文でも分かるので、色だけに頼らない）
    private func messageView(_ message: ParentsMessage) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.cardSpacing) {
            Image(systemName: message.isProblem ? "exclamationmark.circle" : "checkmark.circle")
                .foregroundStyle(message.isProblem ? Palette.text : Palette.accent)
                .accessibilityHidden(true)
            Text(verbatim: message.text)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appFont(Typography.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("parents.message")
    }

    // MARK: - 方針とリンク

    /// 方針の説明（引き継ぎブックの「原則」のうち、保護者に伝えること）
    private var policySection: some View {
        ParentsSection(title: "このアプリの方針") {
            ParentsBullet("広告は表示しません。")
            ParentsBullet("お名前などの個人情報は集めません。アカウントの登録もありません。")
            ParentsBullet("遊んだ記録（スタンプなど）は、この端末の中だけに保存します。")
            ParentsBullet("お子さまの記録を外部に送る通信はしません。パスの価格・購入・復元の確認にだけ App Store を使います。")
        }
    }

    /// プライバシーポリシーとお問い合わせ（Safari で開く。保護者の確認のあとのこの画面にしか出さない）
    private var linksSection: some View {
        ParentsSection(title: "サポート") {
            linkButton("プライバシーポリシー", url: ParentsLinks.privacyPolicy, identifier: "parents.privacy")
            linkButton("お問い合わせ", url: ParentsLinks.contact, identifier: "parents.contact")
            Text("ブラウザで開きます。")
                .appFont(Typography.note)
                .foregroundStyle(Palette.muted)
        }
    }

    private func linkButton(_ title: LocalizedStringKey, url: URL, identifier: String) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: Metrics.cardSpacing) {
                Text(title)
                Image(systemName: "arrow.up.forward.square")
                    .accessibilityHidden(true)
            }
            .appFont(Typography.button)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        .accessibilityHint(Text("ブラウザで開きます"))
        .accessibilityAddTraits(.isLink)
        .accessibilityIdentifier(identifier)
    }

    /// 「ホームにもどる」（仕様書の遷移先はホームだけなので、戻るボタンではなく言葉のボタンにする）
    private var homeButton: some View {
        Button(action: onHome) {
            Text("ホームにもどる")
                .appFont(Typography.button)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        // 購入・復元の途中で戻ると、結果の文を保護者に伝えられないので、終わるまで押せなくする
        .disabled(model.status.isBusy)
        .accessibilityIdentifier("parents.home")
        .padding(.horizontal, Metrics.screenHorizontalPadding)
        .padding(.vertical, Metrics.cardSpacing)
        .background(Palette.background)
    }
}

/// おうちの方への画面のまとまり（面の色の箱・境界線 1。上に見出し）
private struct ParentsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text(title)
                .appFont(Typography.parentsSectionTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.parentsSectionPadding)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.parentsSectionCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.parentsSectionCornerRadius)
                .stroke(Palette.border, lineWidth: Metrics.borderWidth)
        }
    }
}

/// 箇条書きの 1 行（「・」と文。文が折り返しても印の右にそろえる）
private struct ParentsBullet: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.parentsBulletSpacing) {
            Text(verbatim: "・")
                .accessibilityHidden(true)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appFont(Typography.body)
        .foregroundStyle(Palette.text)
    }
}

/// 撮影モードのおうちの方への画面（保護者の確認のあと・パスの購入前）。保存はメモリ上だけで、擬似のストア
struct ParentsScreenshotDemoView: View {
    @State private var passStore: PassStore = {
        let store = InMemoryAppDataStore(data: AppData(hasClearedOnce: true))
        return PassStore(backend: FakePassStoreBackend(entitled: false), dataStore: store)
    }()

    var body: some View {
        ParentsView(passStore: passStore)
            .task {
                await passStore.start()
            }
    }
}

#Preview("購入前") {
    ParentsScreenshotDemoView()
}
