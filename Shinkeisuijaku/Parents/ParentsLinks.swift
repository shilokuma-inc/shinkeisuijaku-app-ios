//
//  ParentsLinks.swift
//  Shinkeisuijaku
//
//  おうちの方への画面に出す外部のリンク（プライバシーポリシーとお問い合わせ）。
//  App Store の掲載（`AppStore/metadata/shared.json` の privacyPolicyUrl・supportUrl。タスク 24 で入れる）と同じ URL を、アプリの中ではここ 1 か所にまとめる。
//  開くのは保護者の確認のあとの画面だけ（子ども向けカテゴリの決まり）。Safari で開き、アプリの中のブラウザは使わない。
//

import Foundation

/// おうちの方への画面の外部のリンク
enum ParentsLinks {
    /// プライバシーポリシー（shilokuma のアプリの決まりの場所。ページの作成は shilokuma-inc/shilokuma-web での人の作業）
    static let privacyPolicy = URL(string: "https://shilokuma.jp/privacy/shinkeisuijaku/")!
    /// お問い合わせ（shilokuma のほかのアプリの supportUrl と同じフォーム）
    static let contact = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSc4DiUAcjKlrchuefXxehD-BgCEhGVomX6NOwtijWiE0yJAlQ/viewform")!
}
