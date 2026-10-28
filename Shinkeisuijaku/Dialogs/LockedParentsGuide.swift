//
//  LockedParentsGuide.swift
//  Shinkeisuijaku
//
//  鍵の付いた難易度を押したあとの案内（仕様書の「ロックされた難易度を押したとき」）。コース選択とクリアのダイアログの中に出す。
//

import SwiftUI

/// 鍵の付いた難易度を押したあとの案内。「おうちの方に あけてもらってね」と、その下の丸い「おうちの方へ」（高さ 44 以上）。
/// コース選択とクリアのダイアログで同じ見た目にする（値段は出さない。押すと保護者の確認が出る）
struct LockedParentsGuide: View {
    /// accessibilityIdentifier の頭（`courseSelect` なら `courseSelect.lockedGuide` と `courseSelect.lockedGuideParents`）
    let identifierPrefix: String
    let onOpenParents: () -> Void

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            Text("おうちの方に あけてもらってね")
                .appFont(Typography.noteStrong)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("\(identifierPrefix).lockedGuide")
            Button("おうちの方へ", action: onOpenParents)
                .buttonStyle(RoundButtonStyle())
                .accessibilityIdentifier("\(identifierPrefix).lockedGuideParents")
        }
    }
}
