//
//  CourseSelectDialogView.swift
//  Shinkeisuijaku
//
//  コース選択のダイアログ（仕様書の「画面と遷移」・引き継ぎブックの 6 ページの「難易度ボタン（鍵つき）」と 7 ページの「ダイアログ」）。
//  見出しはコース名。難易度 3 つ（左に難易度名・右に小さな「6ペア」と、ロック中なら鍵のマーク）と「とじる」。
//  鍵の付いた難易度を押すと、ダイアログの中に「おうちの方に あけてもらってね」と、その下に「おうちの方へ」を出す（値段と購入の画面は子どもに見せない）。
//  「おうちの方へ」を押すと、ダイアログを閉じて保護者の確認を出す（購入が終わったら、押した難易度のゲームを始める）。
//  押したときに始めるか案内かは `CourseSelection` が決め、ゲームを始める・閉じる・保護者の確認を出すのは呼び出し側（`AppFlow`）が行う。
//

import SwiftUI

/// コース選択のダイアログ
struct CourseSelectDialogView: View {
    let selection: CourseSelection
    /// パスの権利があるか（鍵のマークと案内に使う）
    let hasPass: Bool
    /// 難易度を押したとき。始めたか案内を出したかを返す（案内のときは VoiceOver のフォーカスを案内へ移す）
    var onSelect: (Difficulty) -> CourseSelectResult? = { _ in nil }
    /// 「とじる」を押したとき
    var onClose: () -> Void = {}
    /// 案内の下の「おうちの方へ」を押したとき（保護者の確認を出す）
    var onOpenParents: () -> Void = {}

    /// 鍵の案内の文に VoiceOver のフォーカスがあるか（鍵の付いた難易度を押したら、案内へ移す）
    @AccessibilityFocusState private var isLockedGuideFocused: Bool

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
                    // 案内を出したら、VoiceOver のフォーカスを案内の文へ移す（初めて出すときは、案内が出たときに案内の側で移す）
                    if onSelect(option.difficulty) == .showLockedGuide {
                        isLockedGuideFocused = true
                    }
                }
            }
            if selection.showsLockedGuide(hasPass: hasPass) {
                LockedParentsGuide(identifierPrefix: "courseSelect", isFocused: $isLockedGuideFocused, onOpenParents: onOpenParents)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Group {
                if TextSizeLayout.stacksVertically(dynamicTypeSize) {
                    // 文字を大きくしたとき（アクセシビリティの大きさ）は、難易度名が途中で折り返さないよう、「6ペア」と鍵を下の行にする
                    VStack(alignment: .leading, spacing: 0) {
                        name
                            .lineLimit(1)
                            .minimumScaleFactor(Metrics.textMinimumScale)
                        HStack(spacing: Metrics.cardSpacing) {
                            pairs
                            lock
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Metrics.pairCountVerticalPadding)
                } else {
                    HStack(spacing: Metrics.cardSpacing) {
                        name
                        Spacer(minLength: Metrics.cardSpacing)
                        pairs
                        lock
                    }
                }
            }
            .padding(.horizontal, Metrics.difficultyButtonHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
        }
        .buttonStyle(SurfaceButtonStyle())
        // 鍵のマークは絵だけなので、「ふつう 8ペア かぎ」と状態を言葉でまとめて読み上げる
        .accessibilityLabel(Text(verbatim: option.accessibilityLabel))
        .accessibilityHint(Text(verbatim: option.accessibilityHint ?? ""))
        .accessibilityIdentifier("courseSelect.difficulty.\(option.difficulty.rawValue)")
    }

    /// 難易度名（18・800）
    private var name: some View {
        Text(option.difficulty.name)
            .appFont(Typography.difficultyButton)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 右の小さな「6ペア」（12・700）
    private var pairs: some View {
        Text(option.pairsText)
            .appFont(Typography.difficultyPairs)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 鍵のマーク。鍵が無くても場所を空けるときは、同じ大きさの透明な枠
    @ViewBuilder private var lock: some View {
        if option.isLocked {
            LockShape()
                // 鍵のマークはボタンの文字と同じ色（引き継ぎブックの 6 ページの見本の「8ペア」と同じ濃さ。コース選択とクリアでそろえる）
                .fill(Palette.text)
                .frame(width: Metrics.lockIconSize, height: Metrics.lockIconSize)
        } else if reservesLockSpace {
            Color.clear
                .frame(width: Metrics.lockIconSize, height: Metrics.lockIconSize)
        }
    }
}

extension View {
    /// 画面の流れが出しているコース選択のダイアログを、この画面（ホーム）の上に重ねる
    func courseSelectDialog(flow: AppFlow) -> some View {
        modifier(CourseSelectDialogModifier(flow: flow))
    }
}

/// コース選択のダイアログを重ねる。出す・閉じるときは、ほかのダイアログと同じく薄く出し入れする（「視差効果を減らす」ではすぐ切り替える）
private struct CourseSelectDialogModifier: ViewModifier {
    let flow: AppFlow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if let selection = flow.courseSelection {
                    CourseSelectDialogView(
                        selection: selection,
                        hasPass: flow.hasPass,
                        onSelect: flow.selectDifficulty,
                        onClose: flow.closeCourseSelection,
                        onOpenParents: flow.openParentsForLockedCourse
                    )
                    .transition(.opacity)
                }
            }
            .animation(MotionPolicy(reduceMotion: reduceMotion).dialogAnimation, value: flow.courseSelection)
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
