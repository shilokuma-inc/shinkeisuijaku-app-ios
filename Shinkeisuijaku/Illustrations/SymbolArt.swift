//
//  SymbolArt.swift
//  Shinkeisuijaku
//
//  SVG に無い 2 つの絵: ヒントのボタンの目と、ひらがなコースのシンボルの「あ」。
//  引き継ぎブックの 6 ページの部品の見本を見て、13 種類の絵と同じ決まり（輪郭線 `artOutline`・太さ 2.2・表情の線は丸い端）で描く。
//

import SwiftUI

extension IllustrationArt {
    /// ヒントの目の枠（横長。2 つの目と眉）
    static let hintEyesCanvasSize = CGSize(width: 108, height: 54)

    /// ヒントの目: 白目に輪郭線、黒目と小さな光、上に眉の線（2 つ並べる）。
    /// ボタンの面の上に直接置くので、白目の線と眉はダークで明るくなる `artLineOnSurface` にする
    static let hintEyes: [IllustrationPart] = [30.0, 78.0].flatMap { centerX in
        [
            // 白目（ボタンの面の上に置くので、線はダークで明るくなる色）
            IllustrationPart(
                path: Path(ellipseIn: CGRect(x: centerX - 18, y: 14, width: 36, height: 36)),
                fill: Palette.artWhite,
                stroke: Palette.artLineOnSurface,
                lineWidth: Metrics.artOutlineWidth,
                roundCap: false
            ),
            // 黒目（少し下に寄せて、のぞきこむ目にする）
            IllustrationPart(
                path: Path(ellipseIn: CGRect(x: centerX - 7, y: 28, width: 18, height: 18)),
                fill: Palette.artDark,
                stroke: Palette.artOutline,
                lineWidth: Metrics.artOutlineWidth,
                roundCap: false
            ),
            // 黒目の光
            IllustrationPart(
                path: Path(ellipseIn: CGRect(x: centerX + 3, y: 31, width: 5, height: 5)),
                fill: Palette.artWhite,
                stroke: nil,
                lineWidth: 0,
                roundCap: false
            ),
            // 眉
            IllustrationPart(
                path: Path { path in
                    path.move(to: CGPoint(x: centerX - 17, y: 10))
                    path.addQuadCurve(to: CGPoint(x: centerX + 17, y: 10), control: CGPoint(x: centerX, y: 0))
                },
                fill: nil,
                stroke: Palette.artLineOnSurface,
                lineWidth: 3,
                roundCap: true
            )
        ]
    }
}

/// ヒントのボタンの目のアイコン。高さに合わせて拡大・縮小する
struct HintEyesView: View {
    var body: some View {
        IllustrationPartsView(parts: IllustrationArt.hintEyes, canvasSize: IllustrationArt.hintEyesCanvasSize)
    }
}

/// ひらがなコースのシンボルの「あ」（パス専用のスタンプの中に置く）。丸ゴ W4 の文字で、太さは付けない（Q6）
struct HiraganaSymbolView: View {
    var body: some View {
        GeometryReader { proxy in
            Text(verbatim: "あ")
                .font(Typography.stampSymbol(shortSide: min(proxy.size.width, proxy.size.height)))
                .foregroundStyle(Palette.artRed)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        // 読み上げは使う側（スタンプ）で付ける
        .accessibilityHidden(true)
    }
}
