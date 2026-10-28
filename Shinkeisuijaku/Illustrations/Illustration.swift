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
        IllustrationPartsView(
            parts: IllustrationArt.parts(for: picture),
            canvasSize: CGSize(width: Metrics.artCanvasSize, height: Metrics.artCanvasSize)
        )
    }
}

/// 部品の並びを、元の枠（`canvasSize`）の縦横比のまま、与えられた大きさに収まるように拡大・縮小して描く
struct IllustrationPartsView: View {
    let parts: [IllustrationPart]
    /// 部品の座標の枠の大きさ
    let canvasSize: CGSize

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / canvasSize.width, size.height / canvasSize.height)
            context.translateBy(x: (size.width - canvasSize.width * scale) / 2, y: (size.height - canvasSize.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            for part in parts {
                if let fill = part.fill {
                    context.fill(part.path, with: .color(fill))
                }
                if let stroke = part.stroke {
                    let style = StrokeStyle(lineWidth: part.lineWidth, lineCap: part.roundCap ? .round : .butt, lineJoin: .round)
                    context.stroke(part.path, with: .color(stroke), style: style)
                }
            }
        }
        .aspectRatio(canvasSize, contentMode: .fit)
        // 絵の名前の読み上げは、使う側（カード・スタンプ・ボタン）で状態と合わせて付ける
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

/// 絵の見本の画面。上にヒントの目と「あ」、下に 13 種類の絵。撮影モードで開き、添付の画像・引き継ぎブックと見比べるために使う
struct IllustrationCatalogView: View {
    /// 見本の列の数（添付の画像と同じ 3 列）
    private let columns = 3

    var body: some View {
        ScrollView {
            symbols
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

    /// ヒントの目（ボタンの見た目に置く）と、「あ」（金と銀のふちのスタンプに置く）
    private var symbols: some View {
        HStack(spacing: Metrics.screenHorizontalPadding) {
            HStack(spacing: Metrics.cardSpacing) {
                HintEyesView()
                    .frame(height: Metrics.minTapTarget / 2)
                Text("ヒント")
                    .appFont(Typography.button)
                    .foregroundStyle(Palette.text)
            }
            .padding(.horizontal, Metrics.screenHorizontalPadding)
            .frame(minHeight: Metrics.buttonHeight)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius)
                    .stroke(Palette.border, lineWidth: Metrics.borderWidth)
            }
            symbolStamp(rim: Palette.stampSilver, wash: Palette.stampSilverWash)
            symbolStamp(rim: Palette.stampGold, wash: Palette.stampGoldWash)
        }
        .padding(.vertical, Metrics.screenHorizontalPadding)
    }

    /// 「あ」をふちの付いた丸に置いた見本（スタンプの部品はタスク 11 で作る）
    private func symbolStamp(rim: Color, wash: Color) -> some View {
        HiraganaSymbolView()
            .frame(width: Metrics.stampBookMaxDiameter, height: Metrics.stampBookMaxDiameter)
            .background(wash, in: Circle())
            .overlay { Circle().stroke(rim, lineWidth: Metrics.stampRimWidth) }
    }
}

#Preview {
    IllustrationCatalogView()
}
