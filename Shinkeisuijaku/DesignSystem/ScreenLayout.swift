//
//  ScreenLayout.swift
//  Shinkeisuijaku
//
//  画面の配置の共通の決まり。iPad で中身が横に広がりすぎないよう、中身の幅に上限を設けて中央に置く。
//

import SwiftUI

extension View {
    /// 中身（左右の余白を含む列）の幅を `Metrics.contentMaxWidth` までにして、横の真ん中に置く。
    /// 外の枠は横いっぱいに広げるので、この後に付けた背景は画面の幅いっぱいに敷かれる
    func contentWidthLimited() -> some View {
        frame(maxWidth: Metrics.contentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
