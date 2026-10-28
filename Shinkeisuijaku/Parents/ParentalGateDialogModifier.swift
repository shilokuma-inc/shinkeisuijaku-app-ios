//
//  ParentalGateDialogModifier.swift
//  Shinkeisuijaku
//
//  ホームの「おうちの方へ」を押したときに、ホームの上に重ねる保護者の確認のダイアログ。
//  通ったらおうちの方への画面を積み、やめたらホームのまま（何も積まない）。出すかどうかと行き先は `AppFlow` が決める。
//

import SwiftUI

extension View {
    /// 画面の流れが出している保護者の確認のダイアログを、この画面（ホーム）の上に重ねる
    func parentalGateDialog(flow: AppFlow) -> some View {
        modifier(ParentalGateDialogModifier(flow: flow))
    }
}

/// 保護者の確認のダイアログを重ねる。出すたびに新しい問題にする（前に出した問題を続けて出さない）。
/// 出す・閉じるときは、ほかのダイアログと同じく薄く出し入れする
private struct ParentalGateDialogModifier: ViewModifier {
    let flow: AppFlow

    func body(content: Content) -> some View {
        content
            .overlay {
                if flow.isShowingParentalGate {
                    ParentalGateView(onPassed: flow.parentalGatePassed, onCancel: flow.cancelParentalGate)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: Motion.dialogFadeDuration), value: flow.isShowingParentalGate)
    }
}
