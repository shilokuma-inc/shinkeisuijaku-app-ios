//
//  ScreenshotDemo.swift
//  Shinkeisuijaku
//
//  App Store 用スクリーンショットの撮影モード。
//  Tools/capture_screenshots.sh が次の起動引数でアプリを起動し、目的の画面をデモデータで開かせる。
//
//    -screenshot-demo -screenshot-scene <Scene の rawValue> -AppleLanguages (<言語>) -AppleLocale <ロケール>
//
//  画面を足すときは、Scene に case を足し、Shinkeisuijaku.swift の rootView で開く画面を返し、
//  AppStore/screenshots.json の scenes に同じ rawValue を足す（突き合わせは Tools/app_store_config.py が行う）。
//  デモデータは実データと混ざらないよう、撮影モードのときだけメモリ上やインメモリのストアに用意する。
//

import Foundation

enum ScreenshotDemo {
    /// 撮る画面。rawValue が AppStore/screenshots.json の scene と対応する
    enum Scene: String {
        /// ホーム（1 回クリアした後。前回は ひらがな・やさしい）
        case home
        /// デザイントークンの見本（色）。App Store には出さない
        case designTokenColors
        /// デザイントークンの見本（文字・寸法・動き）。App Store には出さない
        case designTokenTypes
        /// 13 種類の絵の見本。App Store には出さない
        case illustrations
        /// カードの 4 つの状態の見本。App Store には出さない
        case cards
        /// スタンプの部品の見本。App Store には出さない
        case stamps
        /// プレイ画面（ひらがな・やさしい。2 組揃えて 1 枚めくった状態）
        case play
        /// クリアのダイアログ（どうぶつ・やさしいを全部揃えてクリアし、スタンプをもらった状態）
        case clear
        /// 保護者の確認のダイアログ（種を固定した問題）。App Store には出さない
        case parentalGate
        /// コース選択のダイアログ（ひらがな。パスの購入前で鍵が付いた状態）
        case courseSelect
        /// スタンプちょう（パスを買った後。通常を 7 つ・パス専用を銀と金の 2 つ集めた状態）
        case stampBook
        /// スタンプちょう（パスを買う前。通常を 7 つ集め、パス専用の枠に鍵が付いた状態）。App Store には出さない（見比べる用）
        case stampBookBeforePass
        /// おうちの方への画面（保護者の確認のあと。購入前）。App Store には出さない
        case parents
    }

    /// 撮影モードで起動するときの起動引数
    static let argument = "-screenshot-demo"

    /// 撮影モードで起動しているか
    static let isEnabled = ProcessInfo.processInfo.arguments.contains(argument)

    /// 撮影モードで開く画面。撮影モードでないときと、知らない値を渡されたときは nil
    static let scene: Scene? = {
        guard isEnabled else {
            return nil
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot-scene"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return Scene(rawValue: arguments[index + 1])
    }()
}
