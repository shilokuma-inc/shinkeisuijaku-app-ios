//
//  ClearDialogView.swift
//  Shinkeisuijaku
//
//  クリアのダイアログ（引き継ぎブックの 7 ページ・仕様書の「クリア」）。スタンプ・「よくできました！」・一言・ボタン。
//  点数・回数は出さない。ボタンを押したときの行き先は呼び出し側（ホームと起動の流れ・購入の流れ）が決める。
//

import SwiftUI

/// クリアのダイアログで押したもの
enum ClearAction: Equatable {
    /// もう一回あそぶ（同じコースと難易度）
    case playAgain
    /// 次の難易度であそぶ（鍵が付いていないとき）
    case nextDifficulty(Difficulty)
    /// スタンプちょう
    case stampBook
    /// ホームにもどる
    case home
    /// 「もっと むずかしいのは おうちの方へ」（おうちの方への画面へ。購入の画面には自動で進まない）
    case parents
}

/// クリアのダイアログ
struct ClearDialogView: View {
    let outcome: ClearOutcome
    /// パスの権利があるか（次の難易度の鍵・おうちの方への案内に使う）
    let hasPass: Bool
    var onAction: (ClearAction) -> Void = { _ in }

    /// 鍵の付いた次の難易度を押したか（「おうちの方に あけてもらってね」を出す）
    @State private var showsLockedGuide = false

    var body: some View {
        DialogContainer {
            ClearStampView(stamp: outcome.awardedStamp ?? .regular(.star))
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
                    Text("おうちの方に あけてもらってね")
                        .appFont(Typography.noteStrong)
                        .foregroundStyle(Palette.text)
                        .accessibilityIdentifier("clear.lockedGuide")
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

    /// 次の難易度のボタン。鍵が付いていたら鍵のマークを付け、押すと案内を出す（値段と購入の画面は子どもに見せない）
    private func nextDifficultyButton(_ next: Difficulty) -> some View {
        let locked = outcome.isNextDifficultyLocked(hasPass: hasPass)
        return Button {
            if locked {
                showsLockedGuide = true
                AccessibilityNotification.Announcement(String(localized: "おうちの方に あけてもらってね")).post()
            } else {
                onAction(.nextDifficulty(next))
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

/// プレイ画面とクリアのダイアログ。クリアになったら記録してもらい（スタンプ・保存・振動）、ダイアログを出す
struct GameScreen: View {
    let session: GameSession
    /// パスの権利があるか（次の難易度の鍵・おうちの方への案内に使う）
    let hasPass: Bool
    let haptics: any Haptics
    let onQuit: () -> Void
    /// クリアを記録して結果を返す（同じゲームで二度呼ばれても 1 回だけ記録する。`AppFlow.recordClear()`）
    let onCleared: () -> ClearOutcome?
    let onClearAction: (ClearAction) -> Void

    @State private var outcome: ClearOutcome?

    var body: some View {
        PlayView(session: session, haptics: haptics, onQuit: onQuit) {
            outcome = onCleared()
        }
        .overlay {
            if let outcome {
                ClearDialogView(outcome: outcome, hasPass: hasPass, onAction: onClearAction)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: Motion.dialogFadeDuration), value: outcome)
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
