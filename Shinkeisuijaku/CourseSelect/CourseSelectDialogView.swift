//
//  CourseSelectDialogView.swift
//  Shinkeisuijaku
//
//  コース選択のダイアログ（仕様書の「画面と遷移」・引き継ぎブックの 6 ページの「難易度ボタン（鍵つき）」と 7 ページの「ダイアログ」）。
//  見出しはコース名。難易度 3 つ（左に難易度名・右に小さな「6ペア」と、ロック中なら鍵のマーク）と「とじる」。
//  鍵の付いた難易度を押すと、ダイアログの中に「おうちの方に あけてもらってね」を出す（値段と購入の画面は子どもに見せない）。
//  押したときに始めるか案内かは `CourseSelection` が決め、ゲームを始める・閉じるのは呼び出し側（`AppFlow`）が行う。
//

import SwiftUI

/// コース選択のダイアログ
struct CourseSelectDialogView: View {
    let selection: CourseSelection
    /// パスの権利があるか（鍵のマークと案内に使う）
    let hasPass: Bool
    /// 難易度を押したとき。始めたか案内を出したかを返す（案内のときは VoiceOver でも読み上げる）
    var onSelect: (Difficulty) -> CourseSelectResult? = { _ in nil }
    /// 「とじる」を押したとき
    var onClose: () -> Void = {}

    var body: some View {
        let options = CourseSelection.options(hasPass: hasPass)
        // 鍵の付いたものがあるときは、鍵の無い行にも鍵の分の場所を空けて、右の「6ペア」の位置をそろえる
        let reservesLockSpace = options.contains(where: \.isLocked)
        DialogContainer {
            Text(selection.course.name)
                .appFont(Typography.dialogTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Metrics.cardSpacing)
            ForEach(options, id: \.difficulty) { option in
                CourseDifficultyButton(option: option, reservesLockSpace: reservesLockSpace) {
                    if onSelect(option.difficulty) == .showLockedGuide {
                        AccessibilityNotification.Announcement(String(localized: "おうちの方に あけてもらってね")).post()
                    }
                }
            }
            if selection.showsLockedGuide(hasPass: hasPass) {
                Text("おうちの方に あけてもらってね")
                    .appFont(Typography.noteStrong)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("courseSelect.lockedGuide")
            }
            Button(action: onClose) {
                Text("とじる")
                    .appFont(Typography.button)
                    .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            }
            .buttonStyle(SurfaceButtonStyle())
            .padding(.top, Metrics.cardSpacing)
            .accessibilityIdentifier("courseSelect.close")
        }
        .accessibilityIdentifier("courseSelect.dialog")
    }
}

/// 難易度ボタン（面の色の地・境界線 1・角丸 14・高さ 52。左に難易度名（18・800）、右に「6ペア」（12・700）と鍵のマーク）
private struct CourseDifficultyButton: View {
    let option: CourseDifficultyOption
    /// 鍵が無くても鍵の分の場所を空けるか
    let reservesLockSpace: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.cardSpacing) {
                Text(option.difficulty.name)
                    .appFont(Typography.difficultyButton)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Metrics.cardSpacing)
                Text(option.pairsText)
                    .appFont(Typography.difficultyPairs)
                    .fixedSize(horizontal: false, vertical: true)
                if option.isLocked {
                    LockShape()
                        .fill(Palette.muted)
                        .frame(width: Metrics.lockIconSize, height: Metrics.lockIconSize)
                        .accessibilityLabel("かぎ")
                } else if reservesLockSpace {
                    Color.clear
                        .frame(width: Metrics.lockIconSize, height: Metrics.lockIconSize)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Metrics.difficultyButtonHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        // 鍵のマークは絵だけなので、「ふつう 8ペア かぎ」と状態を言葉でまとめて読み上げる
        .accessibilityLabel(Text(verbatim: option.accessibilityLabel))
        .accessibilityIdentifier("courseSelect.difficulty.\(option.difficulty.rawValue)")
    }
}

extension View {
    /// 画面の流れが出しているコース選択のダイアログを、この画面（ホーム）の上に重ねる
    func courseSelectDialog(flow: AppFlow) -> some View {
        modifier(CourseSelectDialogModifier(flow: flow))
    }
}

/// コース選択のダイアログを重ねる。出す・閉じるときは、ほかのダイアログと同じく薄く出し入れする
private struct CourseSelectDialogModifier: ViewModifier {
    let flow: AppFlow

    func body(content: Content) -> some View {
        content
            .overlay {
                if let selection = flow.courseSelection {
                    CourseSelectDialogView(
                        selection: selection,
                        hasPass: flow.hasPass,
                        onSelect: flow.selectDifficulty,
                        onClose: flow.closeCourseSelection
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: Motion.dialogFadeDuration), value: flow.courseSelection)
    }
}

/// 撮影モードのコース選択のダイアログ。1 回クリアした後のホームの上に、ひらがなのダイアログを出す（パスの購入前。保存はメモリ上だけで、擬似のストア）
struct CourseSelectScreenshotDemoView: View {
    @State private var flow: AppFlow = {
        let store = InMemoryAppDataStore(data: AppData(lastCourse: .hiragana, hasClearedOnce: true))
        let flow = AppFlow(
            store: store,
            passStore: PassStore(backend: FakePassStoreBackend(entitled: false), dataStore: store),
            haptics: SilentHaptics()
        )
        flow.chooseCourse(.hiragana)
        return flow
    }()

    var body: some View {
        RootView(flow: flow)
    }
}

#Preview {
    CourseSelectScreenshotDemoView()
}
