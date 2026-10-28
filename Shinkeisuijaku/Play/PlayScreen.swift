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
}
