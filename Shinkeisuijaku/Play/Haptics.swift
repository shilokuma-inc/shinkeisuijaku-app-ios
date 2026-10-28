//
//  Haptics.swift
//  Shinkeisuijaku
//
//  振動。端末が対応しているときだけ鳴らす。テスト・UI テスト・撮影モードでは鳴らさない実装に差し替える。
//

import CoreHaptics
import UIKit

/// 振動を鳴らすもの
@MainActor
protocol Haptics {
    /// ペアが揃ったときの軽い振動（25 ミリ秒。`HapticTokens.matchPulseDuration`）
    func matched()
    /// クリアの振動（40・60・40 ミリ秒 = 振動・間・振動）
    func cleared()
}

/// クリアの振動の型（`HapticTokens` の長さで、振動を間をあけて並べる）
enum ClearHapticPattern {
    /// 振動の始まる時刻と長さ（秒）
    static var pulses: [(start: TimeInterval, duration: TimeInterval)] {
        (0..<HapticTokens.clearPulseCount).map { index in
            (Double(index) * (HapticTokens.clearPulseDuration + HapticTokens.clearPulseGap), HapticTokens.clearPulseDuration)
        }
    }
}

/// 端末の振動（`UIImpactFeedbackGenerator`。長さを選べないので、軽い衝撃で 25 ミリ秒に近づける）。
/// 鳴らすのが遅れないよう、generator を持っておき、鳴らすたびに次の分を `prepare()` する
@MainActor
final class SystemHaptics: Haptics {
    private let matchGenerator = UIImpactFeedbackGenerator(style: .light)

    init() {
        matchGenerator.prepare()
    }

    func matched() {
        matchGenerator.impactOccurred()
        matchGenerator.prepare()
    }

    /// Core Haptics で 2 回の振動を鳴らす。対応しない端末と、エンジンを始められないときは鳴らさない
    func cleared() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        do {
            let engine = try CHHapticEngine()
            try engine.start()
            let events = ClearHapticPattern.pulses.map { pulse in
                CHHapticEvent(eventType: .hapticContinuous, parameters: [], relativeTime: pulse.start, duration: pulse.duration)
            }
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameters: []))
            engine.notifyWhenPlayersFinished { _ in .stopEngine }
            try player.start(atTime: CHHapticTimeImmediate)
            clearEngine = engine
        } catch {
            clearEngine = nil
        }
    }

    /// 鳴らしているあいだエンジンを持っておく（すぐに解放すると止まるため）
    private var clearEngine: CHHapticEngine?
}

/// 鳴らさない振動（テスト・UI テスト・撮影モード用）。鳴らした回数だけ数える
@MainActor
final class SilentHaptics: Haptics {
    private(set) var matchedCount = 0
    private(set) var clearedCount = 0

    func matched() {
        matchedCount += 1
    }

    func cleared() {
        clearedCount += 1
    }
}
