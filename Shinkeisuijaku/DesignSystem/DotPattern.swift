//
//  DotPattern.swift
//  Shinkeisuijaku
//
//  水玉の模様（カードの裏・ホームの背景）。間隔・直径・色はデザイントークンから渡す。
//

import SwiftUI

/// 等間隔の水玉。並びを描く場所の真ん中に寄せる（端の水玉が角丸や画面の端で半端に切れないように、余りを両側に分ける）
struct DotPattern: View {
    /// 水玉の中心どうしの間隔
    let spacing: CGFloat
    /// 水玉の直径
    let diameter: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            let columns = max(Int(size.width / spacing), 1)
            let rows = max(Int(size.height / spacing), 1)
            let startX = (size.width - CGFloat(columns - 1) * spacing) / 2
            let startY = (size.height - CGFloat(rows - 1) * spacing) / 2
            var y = startY
            while y < size.height {
                var x = startX
                while x < size.width {
                    let dot = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
                    context.fill(Path(ellipseIn: dot), with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .accessibilityHidden(true)
    }
}
