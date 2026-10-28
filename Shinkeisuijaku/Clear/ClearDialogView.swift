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
            Text(outcome.awardedStamp == nil ? "ぜんぶ あつめたね すごい！" : "あたらしい スタンプを ゲット")
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
            }
            surfaceButton("スタンプちょう", identifier: "clear.stampBook") {
                onAction(.stampBook)
            }
            surfaceButton("ホームにもどる", identifier: "clear.home") {
                onAction(.home)
            }
            if showsLockedGuide {
                Text("おうちの方に あけてもらってね")
                    .appFont(Typography.noteStrong)
                    .foregroundStyle(Palette.text)
                    .accessibilityIdentifier("clear.lockedGuide")
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

/// プレイ画面とクリアのダイアログ。クリアになったらスタンプを決めて保存し、振動を鳴らしてダイアログを出す
struct GameScreen: View {
    let session: GameSession
    let store: any AppDataStore
    /// パスの権利があるか（StoreKit の権利。ストアはタスク 17）
    let hasPass: Bool
    let haptics: any Haptics
    var onQuit: () -> Void = {}
    var onClearAction: (ClearAction) -> Void = { _ in }

    @State private var outcome: ClearOutcome?

    var body: some View {
        PlayView(session: session, haptics: haptics, onQuit: onQuit) {
            recordClear()
        }
        .overlay {
            if let outcome {
                ClearDialogView(outcome: outcome, hasPass: hasPass, onAction: onClearAction)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: Motion.flipDuration), value: outcome)
        // もう一回あそぶ・次の難易度で新しいゲームが来たら、ダイアログを閉じる
        .onChange(of: ObjectIdentifier(session)) {
            outcome = nil
        }
    }

    /// クリアの結果を決めて保存する（同じゲームで二度記録しない）
    private func recordClear() {
        guard outcome == nil else {
            return
        }
        var generator = SystemRandomNumberGenerator()
        let result = ClearOutcome.make(
            course: session.course,
            difficulty: session.difficulty,
            data: store.load(),
            hasPass: hasPass,
            using: &generator
        )
        store.save(result.data)
        haptics.cleared()
        outcome = result
    }
}

/// 撮影モードのクリアのダイアログ。プレイ画面の上に、通常のスタンプを 1 つもらった やさしい のクリアを出す（種を固定。保存しない）
struct ClearScreenshotDemoView: View {
    var body: some View {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let outcome = ClearOutcome.make(
            course: .animals,
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
