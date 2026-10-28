//
//  Illustration.swift
//  Shinkeisuijaku
//
//  13 種類の絵を描く。形は Discussion #4 の Q1 の添付の SVG を `Tools/illustrations/convert.py` で
//  `Generated/` の Path に変換したもの（手で写さない）。ベクターなので、どの大きさでも崩れない。
//  引き継ぎブックの「軽いゆらぎ」は入れない。
//

import SwiftUI

/// 絵の部品 1 つ（SVG の path・circle・ellipse 1 つ分）。座標は 108×108 の枠の中の値
struct IllustrationPart {
    let path: Path
    /// 塗りの色。塗らない線だけの部品は nil
    let fill: Color?
    /// 線の色。線の無い部品は nil
    let stroke: Color?
    /// 線の太さ（枠が 108×108 のときの値。絵の大きさに合わせて太さも変わる）
    let lineWidth: CGFloat
    /// 線の端を丸くするか（表情の線など）
    let roundCap: Bool
}

/// 絵ごとの部品の並び（下から順に重ねる）
enum IllustrationArt {
    /// 絵の部品。`Generated/` の書き出したコードから引く。
    /// 絵を足したときに書き忘れがコンパイルで分かるよう、辞書ではなく網羅した switch にする（分岐が多いのはそのため）
    static func parts(for picture: Picture) -> [IllustrationPart] { // swiftlint:disable:this cyclomatic_complexity
        switch picture {
        case .cat: cat
        case .dog: dog
        case .rabbit: rabbit
        case .panda: panda
        case .frog: frog
        case .chick: chick
        case .fox: fox
        case .penguin: penguin
        case .apple: apple
        case .strawberry: strawberry
        case .bear: bear
        case .suika: suika
        case .star: star
        }
    }
}

/// 絵 1 つ。与えられた大きさの正方形に収まるように拡大・縮小して描く
struct IllustrationView: View {
    let picture: Picture

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let scale = side / Metrics.artCanvasSize
            context.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            context.scaleBy(x: scale, y: scale)
            for part in IllustrationArt.parts(for: picture) {
                if let fill = part.fill {
                    context.fill(part.path, with: .color(fill))
                }
                if let stroke = part.stroke {
                    let style = StrokeStyle(lineWidth: part.lineWidth, lineCap: part.roundCap ? .round : .butt, lineJoin: .round)
                    context.stroke(part.path, with: .color(stroke), style: style)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        // 絵の名前の読み上げは、使う側（カード・スタンプ）で状態と合わせて付ける
        .accessibilityHidden(true)
    }
}

extension Path {
    /// 点のまわりに回した Path（SVG の `rotate(角度 x y)`）
    func rotated(by degrees: Double, around center: CGPoint) -> Path {
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -center.x, y: -center.y)
        return applying(transform)
    }
}

/// 13 種類の絵を並べた見本の画面。撮影モードで開き、添付の画像と見比べるために使う
struct IllustrationCatalogView: View {
    /// 見本の列の数（添付の画像と同じ 3 列）
    private let columns = 3

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Metrics.cardSpacing), count: columns),
                spacing: Metrics.cardSpacing
            ) {
                ForEach(Picture.allCases, id: \.self) { picture in
                    VStack(spacing: 0) {
                        IllustrationView(picture: picture)
                            .padding(Metrics.cardSpacing)
                        Text(verbatim: "\(picture.rawValue)（\(picture.name)）")
                            .appFont(Typography.noteStrong)
                            .foregroundStyle(Palette.cardInk)
                            .padding(.bottom, Metrics.cardSpacing)
                    }
                    .background(Palette.cardPicture, in: RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
                }
            }
            .padding(.horizontal, Metrics.screenHorizontalPadding)
        }
        .background(Palette.background)
    }
}

#Preview {
    IllustrationCatalogView()
}
