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
            VStack(spacing: Metrics.cardSpacing) {
                content()
            }
            .padding(.vertical, Metrics.dialogVerticalPadding)
            .padding(.horizontal, Metrics.dialogHorizontalPadding)
            .frame(maxWidth: Metrics.dialogMaxWidth)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.dialogCornerRadius))
            .padding(.horizontal, Metrics.screenHorizontalPadding)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}

/// 主なボタン（強調色の地・文字は強調の上の文字の色・角丸 14・高さ 52・文字は 15 の 800）
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(Typography.primaryButton)
            .foregroundStyle(Palette.accentText)
            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
            .opacity(configuration.isPressed ? Metrics.pressedOpacity : 1)
    }
}
