//
//  PlayScreen.swift
//  Shinkeisuijaku
//
//  プレイ画面で決めること（「あと◯ペア」の読み上げ・ヒントのボタンを押せる見た目にするか）。
//  View から切り離した純粋な関数にして、単体テストする。
//

import Foundation

/// プレイ画面の決まり
enum PlayScreen {
    /// 「あと◯ペア」の札の読み上げ（「ひらがな あと 4 ペア」）。札は 1 つの要素にまとめ、見た目と同じ順に読む
    static func remainingPairsLabel(course: Course, remainingPairs: Int) -> String {
        String(localized: "\(course.name) あと \(remainingPairs) ペア")
    }

    /// ヒントのボタンを押せる見た目にするか。ハズレを裏に戻すまで（0.9 秒）とヒントを見せているあいだ（1.1 秒）は、
    /// 押しても何もしない（`GameSession.showHint()` が `.playing` のときだけ進める）が、薄くしない（遊ぶたびにボタンがちらつかないように）。
    /// 始めに全部見せているあいだ・揃ってクリアを待っているあいだ・クリアの後・やめた後は、しばらく押せないので薄くする
    static func hintLooksEnabled(phase: GameSession.Phase) -> Bool {
        switch phase {
        case .playing, .resolvingMismatch, .hinting:
            true
        case .ready, .revealingAll, .finishing, .cleared, .quit:
            false
        }
    }
}
