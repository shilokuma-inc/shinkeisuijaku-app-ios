//
//  Haptics.swift
//  Shinkeisuijaku
//
//  振動。端末が対応しているときだけ鳴らす。テスト・UI テスト・撮影モードでは鳴らさない実装に差し替える。
//

import UIKit

/// 振動を鳴らすもの
@MainActor
protocol Haptics {
    /// ペアが揃ったときの軽い振動（25 ミリ秒。`HapticTokens.matchPulseDuration`）
    func matched()
}

/// 端末の振動（`UIImpactFeedbackGenerator`。長さを選べないので、軽い衝撃で 25 ミリ秒に近づける）
struct SystemHaptics: Haptics {
    func matched() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

/// 鳴らさない振動（テスト・UI テスト・撮影モード用）。鳴らした回数だけ数える
@MainActor
final class SilentHaptics: Haptics {
    private(set) var matchedCount = 0

    func matched() {
        matchedCount += 1
    }
}
