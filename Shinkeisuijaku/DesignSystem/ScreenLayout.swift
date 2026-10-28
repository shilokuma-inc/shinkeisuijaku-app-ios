//
//  ScreenLayout.swift
//  Shinkeisuijaku
//
//  画面の配置の共通の決まり。iPad で中身が横に広がりすぎないよう、中身の幅に上限を設けて中央に置く。
//  スクロールする画面（ホーム・スタンプちょう・おうちの方へ）では、上の安全領域に背景を敷いて、中身がステータスバーに重ならないようにする。
//

import SwiftUI

extension View {
    /// 上の安全領域（ステータスバーの下）に、画面の背景と同じものを重ねて敷く。スクロールした中身がステータスバーの下で透けて読みにくくならないように。
    /// 背景は画面いっぱいの大きさで描いてから上の安全領域の分だけ見せるので、水玉などの模様も画面の背景とずれない。押した操作は下に通す
    /// - Parameter background: 画面の背景（`ignoresSafeArea()` で画面いっぱいに敷いているものと同じもの）
    func topSafeAreaBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        let backdrop = background()
        return overlay {
            // 読み取りの枠ごと安全領域の外まで広げる（枠が安全領域の内側にあると、上の安全領域の高さが 0 と読めてしまう）
            GeometryReader { proxy in
                backdrop
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: proxy.safeAreaInsets.top)
                    }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// 中身（左右の余白を含む列）の幅を `Metrics.contentMaxWidth` までにして、横の真ん中に置く。
    /// 外の枠は横いっぱいに広げるので、この後に付けた背景は画面の幅いっぱいに敷かれる
    func contentWidthLimited() -> some View {
        frame(maxWidth: Metrics.contentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
