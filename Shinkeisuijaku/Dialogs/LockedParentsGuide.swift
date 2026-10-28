//
//  LockedParentsGuide.swift
//  Shinkeisuijaku
//
//  鍵の付いた難易度を押したあとの案内（仕様書の「ロックされた難易度を押したとき」）。コース選択とクリアのダイアログの中に出す。
//

import SwiftUI

/// 鍵の付いた難易度を押したあとの案内。「おうちの方に あけてもらってね」と、その下の丸い「おうちの方へ」（高さ 44 以上）。
/// コース選択とクリアのダイアログで同じ見た目にする（値段は出さない。押すと保護者の確認が出る）。
/// VoiceOver では、出たときに案内の文へフォーカスを移して読み上げる（押した直後の読み上げの通知は、ボタンの読み上げに消されることがあるため）
struct LockedParentsGuide: View {
    /// accessibilityIdentifier の頭（`courseSelect` なら `courseSelect.lockedGuide` と `courseSelect.lockedGuideParents`）
    let identifierPrefix: String
    /// 案内の文に VoiceOver のフォーカスがあるか。出たときと、案内を出したまま鍵の付いた難易度をもう一度押したときに、呼び出し側が true にする
    let isFocused: AccessibilityFocusState<Bool>.Binding
    let onOpenParents: () -> Void

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            Text("おうちの方に あけてもらってね")
                .appFont(Typography.noteStrong)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityFocused(isFocused)
                .accessibilityIdentifier("\(identifierPrefix).lockedGuide")
            Button("おうちの方へ", action: onOpenParents)
                .buttonStyle(RoundButtonStyle())
                .accessibilityIdentifier("\(identifierPrefix).lockedGuideParents")
        }
        .onAppear {
            isFocused.wrappedValue = true
        }
    }
}
