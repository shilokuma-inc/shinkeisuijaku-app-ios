//
//  MotionPolicy.swift
//  Shinkeisuijaku
//
//  「視差効果を減らす」（`accessibilityReduceMotion`）のときに、どの動きを止めるかの決まり（引き継ぎブックの 9 ページの「動きを減らす設定」）。
//  オンのときは、めくりの回転・揃ったときのふくらみ・ダイアログの出し入れを止めて、切り替えるだけにする。
//  揃ってから緑になるまでの間（0.35 秒）は動きではないので、オンでも同じだけ待つ（めくった表を見てから緑になる）。
//  クリアのスタンプのかたむき（8 度）は止まった形なので、オンでもそのまま。
//  View から切り離した値の型にして、単体テストする。
//

import SwiftUI

/// 動きを付けるかの決まり
struct MotionPolicy: Equatable {
    /// 「視差効果を減らす」がオンか
    let reduceMotion: Bool

    /// カードをめくるときに Y 軸まわりに回すか（オフなら裏と表を切り替えるだけ）
    var rotatesOnFlip: Bool {
        !reduceMotion
    }

    /// ペアが揃ったときにふくらむか（オフなら緑に切り替えるだけ）
    var pulsesOnMatch: Bool {
        !reduceMotion
    }

    /// ダイアログ（クリア・コース選択・保護者の確認）を薄く出し入れするか（オフならすぐ出して、すぐ消す）
    var fadesDialogs: Bool {
        !reduceMotion
    }

    /// ペアが揃ってから緑にするまでの間。「視差効果を減らす」でも同じ（動きではなく、めくった表を見せる間のため）
    var matchDelay: TimeInterval {
        Motion.matchDelay
    }

    /// めくりの動き（回さないときは nil で、すぐ切り替える）
    var flipAnimation: Animation? {
        rotatesOnFlip ? .easeInOut(duration: Motion.flipDuration) : nil
    }

    /// ダイアログの出し入れの動き（薄く出し入れしないときは nil）
    var dialogAnimation: Animation? {
        fadesDialogs ? .easeOut(duration: Motion.dialogFadeDuration) : nil
    }
}
