//
//  Motion.swift
//  Shinkeisuijaku
//
//  引き継ぎブックの「動き」を写した秒数・倍率と、振動の長さのトークン。
//  画面とゲームのモデルは秒数を直接書かず、ここの値だけを使う（Discussion #4 の決めで、仕様書の「約 5 秒」「約 1 秒」ではなく引き継ぎブックの値）。
//

import Foundation

/// アプリで使う動きの秒数と倍率。値は引き継ぎブックの「動き」と同じ
enum Motion {
    // カード
    /// カードをめくる時間（Y 軸まわりに 180 度、イーズ）
    static let flipDuration: TimeInterval = 0.28
    /// めくるときの回転の角度（度）
    static let flipAngleDegrees: Double = 180
    /// ペアが揃ってから、緑になってふくらむまでの間
    static let matchDelay: TimeInterval = 0.35
    /// ペアが揃ったときにふくらむ倍率
    static let matchScale: CGFloat = 1.06
    /// ハズレの 2 枚が裏に戻るまでの時間（× 表示や音は出さない）
    static let mismatchDelay: TimeInterval = 0.9

    // 全部見せる・ヒント・クリア
    /// 始めに全部見せる時間（6 ペア）
    static let revealAllSixPairs: TimeInterval = 2.6
    /// 始めに全部見せる時間（8 ペア）
    static let revealAllEightPairs: TimeInterval = 3.0
    /// 始めに全部見せる時間（10 ペア）
    static let revealAllTenPairs: TimeInterval = 3.4
    /// 初回クリア前のゲームで始めに全部見せる時間（ペアの数によらない）
    static let revealAllBeforeFirstClear: TimeInterval = 4.8
    /// ヒントで裏のカードを全部見せる時間（回数の制限はなし）
    static let hintDuration: TimeInterval = 1.1
    /// 全部揃ってから、クリアのダイアログを出すまでの間
    static let clearDialogDelay: TimeInterval = 1.1

    /// 始めに全部見せる時間。初回クリア前は 4.8 秒、それ以降はペアの数で決まる
    /// - Parameters:
    ///   - pairCount: ペアの数（6・8・10）。ほかの数は近い方に寄せる
    ///   - isBeforeFirstClear: まだ 1 回もクリアしていないか
    static func revealAllDuration(pairCount: Int, isBeforeFirstClear: Bool) -> TimeInterval {
        if isBeforeFirstClear {
            return revealAllBeforeFirstClear
        }
        switch pairCount {
        case ...6:
            return revealAllSixPairs
        case 7...8:
            return revealAllEightPairs
        default:
            return revealAllTenPairs
        }
    }
}

/// 振動の長さ。鳴らすのは端末が対応しているときだけ
enum HapticTokens {
    /// ペアが揃ったときの軽い振動の長さ（`UIImpactFeedbackGenerator(style: .light)` で鳴らす）
    static let matchPulseDuration: TimeInterval = 0.025
    /// クリアの振動の 1 回の長さ（40 ミリ秒）
    static let clearPulseDuration: TimeInterval = 0.04
    /// クリアの振動の 2 回の間（60 ミリ秒）
    static let clearPulseGap: TimeInterval = 0.06
    /// クリアの振動の回数（40・60・40 ミリ秒 = 振動・間・振動）
    static let clearPulseCount = 2
}
