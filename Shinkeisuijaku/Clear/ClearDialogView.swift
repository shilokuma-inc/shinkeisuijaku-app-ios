//
//  ClearDialogView.swift
//  Shinkeisuijaku
//
//  クリアのダイアログ（引き継ぎブックの 7 ページ・仕様書の「クリア」）。スタンプ・「よくできました！」・一言・ボタン。
//  点数・回数は出さない。ボタンを押したときの行き先は呼び出し側（ホームと起動の流れ・購入の流れ。`AppFlow.handle`）が決める。
//  鍵の付いた次の難易度を押したら、呼び出し側が押したものを覚え、ここに「おうちの方に あけてもらってね」と「おうちの方へ」を出す。
//

import SwiftUI

/// クリアのダイアログで押したもの
enum ClearAction: Equatable {
    /// もう一回あそぶ（同じコースと難易度）
    case playAgain
    /// 次の難易度であそぶ。鍵が付いていたら始めずに、押したものを覚えて「おうちの方に あけてもらってね」を出す
    case nextDifficulty(Difficulty)
    /// スタンプちょう
    case stampBook
    /// ホームにもどる
    case home
    /// 鍵の案内の下の「おうちの方へ」（保護者の確認を通ったら、おうちの方への画面へ。購入が終わったら、押した次の難易度を始める）
    case lockedGuideParents
    /// 「もっと むずかしいのは おうちの方へ」（保護者の確認を通ったら、おうちの方への画面へ。購入の画面には自動で進まない）
    case parents
}

/// クリアのダイアログ
struct ClearDialogView: View {
    let outcome: ClearOutcome
    /// パスの権利があるか（次の難易度の鍵・おうちの方への案内に使う）
    let hasPass: Bool
    /// 「おうちの方に あけてもらってね」を出すか（鍵の付いた次の難易度を押した後。パスを買ったら消す。`AppFlow.showsClearLockedGuide`）
    var showsLockedGuide = false
    var onAction: (ClearAction) -> Void = { _ in }

    var body: some View {
        DialogContainer {
            ClearStampView(stamp: outcome.awardedStamp ?? .regular(.star), accessibilityLabel: outcome.stampAccessibilityLabel)
                .padding(.bottom, Metrics.cardSpacing)
            Text("よくできました！")
                .appFont(Typography.dialogTitle)
                .foregroundStyle(Palette.text)
            Text(outcome.awardedStamp == nil ? "いっぱい あつめたね すごい！" : "あたらしい スタンプを ゲット")
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
                .padding(.bottom, Metrics.cardSpacing)
            Button("もう一回あそぶ") {
                onAction(.playAgain)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("clear.playAgain")
            if let next = outcome.nextDifficulty {
                nextDifficultyButton(next)
                if showsLockedGuide {
                    LockedParentsGuide(identifierPrefix: "clear") {
                        onAction(.lockedGuideParents)
                    }
                }
            }
            surfaceButton("スタンプちょう", identifier: "clear.stampBook") {
                onAction(.stampBook)
            }
            surfaceButton("ホームにもどる", identifier: "clear.home") {
                onAction(.home)
            }
            if ClearOutcome.showsParentsGuide(hasPass: hasPass) {
                Button {
                    onAction(.parents)
                } label: {
                    Text("もっと むずかしいのは おうちの方へ")
                        .appFont(Typography.note)
                        .foregroundStyle(Palette.muted)
                        .underline()
                        .frame(minHeight: Metrics.minTapTarget)
                }
                .accessibilityIdentifier("clear.parents")
            }
        }
        .accessibilityIdentifier("clear.dialog")
    }

    /// 次の難易度のボタン。鍵が付いていたら鍵のマークを付け、押すと（呼び出し側が始めずに覚えて）案内を出す（値段と購入の画面は子どもに見せない）
    private func nextDifficultyButton(_ next: Difficulty) -> some View {
        let locked = outcome.isNextDifficultyLocked(hasPass: hasPass)
        return Button {
            onAction(.nextDifficulty(next))
            if locked {
                AccessibilityNotification.Announcement(String(localized: "おうちの方に あけてもらってね")).post()
            }
        } label: {
            HStack(spacing: Metrics.cardSpacing) {
                Text("\(next.name)で あそぶ")
                    .appFont(Typography.button)
                if locked {
                    LockShape()
                        .fill(Palette.muted)
                        .frame(width: Metrics.lockIconSize, height: Metrics.lockIconSize)
                        .accessibilityLabel("かぎ")
                }
            }
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        .accessibilityIdentifier("clear.nextDifficulty")
    }

    private func surfaceButton(_ title: LocalizedStringKey, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(Typography.button)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        .accessibilityIdentifier(identifier)
    }
}

/// クリアを 1 回だけ記録する（スタンプを決めて保存し、振動を鳴らす）。ゲームごとに作る
@MainActor
final class ClearRecorder {
    let course: Course
    let difficulty: Difficulty
    /// 記録したクリアの結果（まだなら nil）
    private(set) var outcome: ClearOutcome?

    init(course: Course, difficulty: Difficulty) {
        self.course = course
        self.difficulty = difficulty
    }

    /// クリアを記録する。同じゲームで二度呼んでも、2 回目は保存も振動もせずに 1 回目の結果を返す
    @discardableResult
    func record(
        store: any AppDataStore,
        hasPass: Bool,
        haptics: any Haptics,
        using generator: inout some RandomNumberGenerator
    ) -> ClearOutcome {
        if let outcome {
            return outcome
        }
        let result = ClearOutcome.make(course: course, difficulty: difficulty, data: store.load(), hasPass: hasPass, using: &generator)
        store.save(result.data)
        haptics.cleared()
        outcome = result
        return result
    }
}

/// プレイ画面とクリアのダイアログ。クリアになったら記録してもらい（スタンプ・保存・振動）、ダイアログを出す（薄く出す。「視差効果を減らす」ではすぐ出す。スタンプのかたむきは止まった形なのでそのまま）
struct GameScreen: View {
    let session: GameSession
    /// パスの権利があるか（次の難易度の鍵・おうちの方への案内に使う）
    let hasPass: Bool
    /// クリアのダイアログに鍵の案内を出すか（`AppFlow.showsClearLockedGuide`）
    let showsLockedGuide: Bool
    let haptics: any Haptics
    let onQuit: () -> Void
    /// クリアを記録して結果を返す（同じゲームで二度呼ばれても 1 回だけ記録する。`AppFlow.recordClear()`）
    let onCleared: () -> ClearOutcome?
    let onClearAction: (ClearAction) -> Void

    @State private var outcome: ClearOutcome?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PlayView(session: session, haptics: haptics, onQuit: onQuit) {
            outcome = onCleared()
        }
        .overlay {
            if let outcome {
                ClearDialogView(outcome: outcome, hasPass: hasPass, showsLockedGuide: showsLockedGuide, onAction: onClearAction)
                    .transition(.opacity)
            }
        }
        .animation(MotionPolicy(reduceMotion: reduceMotion).dialogAnimation, value: outcome)
        // もう一回あそぶ・次の難易度で新しいゲームが来たら、ダイアログを閉じる（記録は呼び出し側がゲームごとにやり直す）
        .onChange(of: ObjectIdentifier(session)) {
            outcome = nil
        }
    }
}

/// 撮影モードのクリアのダイアログ。プレイ画面（ひらがな）の上に、通常のスタンプを 1 つもらった ひらがな・やさしい のクリアを出す（種を固定。保存しない）
struct ClearScreenshotDemoView: View {
    var body: some View {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let outcome = ClearOutcome.make(
            course: .hiragana,
            difficulty: .easy,
            data: AppData(ownedStampIDs: Stamp.regularStamps.filter { $0 != .regular(.fox) }.prefix(4).map(\.id)),
            hasPass: false,
            using: &generator
        )
        return ZStack {
            PlayScreenshotDemoView()
            ClearDialogView(outcome: outcome, hasPass: false)
        }
    }
}
