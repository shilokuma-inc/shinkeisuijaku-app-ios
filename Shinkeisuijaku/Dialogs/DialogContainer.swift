//
//  DialogContainer.swift
//  Shinkeisuijaku
//
//  ダイアログの入れ物（引き継ぎブックの 7 ページ）。暗い半透明の幕（黒 45%）の上に、面の色の箱（幅 320 まで・角丸 22・余白 24×20）を出す。
//  クリア・コース選択・保護者の確認のダイアログで使う。
//

import SwiftUI

/// 幕の上に面の色の箱を出す。幕を押しても閉じない（子どもがうっかり閉じないように。閉じるのは箱の中のボタン）
struct DialogContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Palette.dialogScrim
                .ignoresSafeArea()
                .accessibilityHidden(true)
            // いつもスクロールの中に置き、画面の高さより低いときは真ん中に置く（入らないとき（iPhone SE で文字を大きくしたときなど）だけスクロールする）。
            // 入るか入らないかで中身を作り直さないので、文字の大きさが変わっても VoiceOver のフォーカスが外れない
            GeometryReader { proxy in
                ScrollView {
                    box
                        .padding(.horizontal, Metrics.screenHorizontalPadding)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private var box: some View {
        VStack(spacing: Metrics.cardSpacing) {
            content()
        }
        .padding(.vertical, Metrics.dialogVerticalPadding)
        .padding(.horizontal, Metrics.dialogHorizontalPadding)
        .frame(maxWidth: Metrics.dialogMaxWidth)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.dialogCornerRadius))
    }
}

/// ボタンの薄さの決まり（通常のボタン・主なボタン・丸いボタンで同じ）
enum ButtonOpacity {
    /// 押しているあいだは `Metrics.pressedOpacity`、押せないときは `Metrics.disabledOpacity`、それ以外は薄くしない
    static func value(isPressed: Bool, isEnabled: Bool) -> Double {
        if !isEnabled {
            return Metrics.disabledOpacity
        }
        return isPressed ? Metrics.pressedOpacity : 1
    }
}

/// 主なボタン（強調色の地・文字は強調の上の文字の色・角丸 14・高さ 52・文字は 15 の 800）。押しているあいだと押せないときは薄くする
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }

    private struct PrimaryButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .appFont(Typography.primaryButton)
                .foregroundStyle(Palette.accentText)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
                .opacity(ButtonOpacity.value(isPressed: configuration.isPressed, isEnabled: isEnabled))
        }
    }
}

/// 丸いボタン（面の色の地・境界線 1・角丸は完全な丸・高さ 44 以上・文字は 15 の 700）。ホームの上の右と、鍵の案内の下の「おうちの方へ」。
/// 押しているあいだは薄くする
struct RoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(Typography.button)
            .foregroundStyle(Palette.text)
            .padding(.horizontal, Metrics.roundButtonHorizontalPadding)
            .frame(minHeight: Metrics.roundButtonMinHeight)
            .background(Palette.surface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Palette.border, lineWidth: Metrics.borderWidth)
            }
            .contentShape(Capsule())
            // 丸いボタンは押せなくすることが無いので、押しているあいだだけ薄くする
            .opacity(ButtonOpacity.value(isPressed: configuration.isPressed, isEnabled: true))
    }
}
