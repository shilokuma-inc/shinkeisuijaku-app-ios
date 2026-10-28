//
//  Typography.swift
//  Shinkeisuijaku
//
//  引き継ぎブックの「文字」の表を写した文字のトークン。
//  画面はフォントの大きさ・太さを直接書かず、`.appFont(_:)` とカードの文字の関数だけを使う。
//

import SwiftUI

/// 文字の用途ごとの大きさ・太さ・字間
struct TypographyToken: Sendable {
    /// 書体
    enum Face: Sendable {
        /// ヒラギノ丸ゴ W4。太さは付けない（Discussion #4 の Q6）
        case rounded
        /// システムの書体（ヒラギノ角ゴ）と太さ
        case system(Font.Weight)
    }

    /// iPhone の標準の文字の大きさでの pt
    let size: CGFloat
    let face: Face
    /// 字間（em。文字の大きさに対する割合）
    let trackingEm: CGFloat
    /// Dynamic Type で大きさを合わせる基準
    let relativeTo: Font.TextStyle

    init(size: CGFloat, face: Face, trackingEm: CGFloat = 0, relativeTo: Font.TextStyle) {
        self.size = size
        self.face = face
        self.trackingEm = trackingEm
        self.relativeTo = relativeTo
    }
}

/// アプリで使う文字。値は引き継ぎブックの「文字」と同じ（太さ 800 は `.heavy`、700 は `.bold`、400 は `.regular`）
enum Typography {
    /// ヒラギノ丸ゴの PostScript 名。端末に入っている書体を使い、同梱しない（Q6）
    static let roundedFontName = "HiraMaruProN-W4"

    /// ホームのタイトル（32・丸ゴ・字間 0.02em）
    static let homeTitle = TypographyToken(size: 32, face: .rounded, trackingEm: 0.02, relativeTo: .largeTitle)
    /// 大きな「あそぶ」（30・800・字間 0.1em）
    static let playButton = TypographyToken(size: 30, face: .system(.heavy), trackingEm: 0.1, relativeTo: .title)
    /// 「あと◯ペア」の数字（24・800。色は強調色）
    static let pairCountNumber = TypographyToken(size: 24, face: .system(.heavy), relativeTo: .title2)
    /// 「あと◯ペア」の文字（17・800）
    static let pairCountLabel = TypographyToken(size: 17, face: .system(.heavy), relativeTo: .headline)
    /// ダイアログの見出し（22・800）
    static let dialogTitle = TypographyToken(size: 22, face: .system(.heavy), relativeTo: .title2)
    /// 難易度ボタン（ダイアログ）の文字（18・800）
    static let difficultyButton = TypographyToken(size: 18, face: .system(.heavy), relativeTo: .title3)
    /// 難易度ボタンの右の小さな「6ペア」（12・700）
    static let difficultyPairs = TypographyToken(size: 12, face: .system(.bold), relativeTo: .caption)
    /// ボタンの文字（15・700）
    static let button = TypographyToken(size: 15, face: .system(.bold), relativeTo: .subheadline)
    /// 主なボタンの文字（15・800）
    static let primaryButton = TypographyToken(size: 15, face: .system(.heavy), relativeTo: .subheadline)
    /// 説明文（14・400。色は補助の文字）
    static let body = TypographyToken(size: 14, face: .system(.regular), relativeTo: .subheadline)
    /// 小さな注記（12・400。色は補助の文字）
    static let note = TypographyToken(size: 12, face: .system(.regular), relativeTo: .caption)
    /// 小さな注記の強いもの（12・700。色は補助の文字）
    static let noteStrong = TypographyToken(size: 12, face: .system(.bold), relativeTo: .caption)
    /// おうちの方への画面のまとまりの見出し（引き継ぎブックに無いので、「あと◯ペア」の文字と同じ 17・800 にした）
    static let parentsSectionTitle = TypographyToken(size: 17, face: .system(.heavy), relativeTo: .headline)

    // カードの文字は、カードの短辺に対する割合で大きさを決める
    /// ひらがなカードの文字（短辺の 66%・丸ゴ）
    static let cardLetterRatio: CGFloat = 0.66
    /// ペアが揃うと現れる言葉（短辺の 15%・丸ゴ）
    static let cardWordRatio: CGFloat = 0.15
    /// カードの裏の「？」（短辺の 34%・800）
    static let cardQuestionRatio: CGFloat = 0.34

    /// パス専用のスタンプの「あ」（丸の短辺の 55%・丸ゴ。引き継ぎブックの 6 ページの見本の大きさ）
    static let stampSymbolRatio: CGFloat = 0.55

    /// パス専用のスタンプの「あ」のフォント。スタンプの大きさで決まるので Dynamic Type では変えない
    static func stampSymbol(shortSide: CGFloat) -> Font {
        .custom(roundedFontName, fixedSize: shortSide * stampSymbolRatio)
    }

    /// ひらがなカードの文字のフォント。カードの大きさで決まるので Dynamic Type では変えない（カードからはみ出さないため）
    static func cardLetter(shortSide: CGFloat) -> Font {
        .custom(roundedFontName, fixedSize: shortSide * cardLetterRatio)
    }

    /// ペアが揃うと現れる言葉のフォント。カードの大きさで決まるので Dynamic Type では変えない
    static func cardWord(shortSide: CGFloat) -> Font {
        .custom(roundedFontName, fixedSize: shortSide * cardWordRatio)
    }

    /// カードの裏の「？」のフォント。カードの大きさで決まるので Dynamic Type では変えない
    static func cardQuestion(shortSide: CGFloat) -> Font {
        .system(size: shortSide * cardQuestionRatio, weight: .heavy)
    }
}

/// 文字のトークンを Dynamic Type に合わせて当てる
private struct TypographyModifier: ViewModifier {
    let token: TypographyToken
    /// Dynamic Type の倍率。システムの書体の大きさと字間に掛ける
    @ScaledMetric private var scale: CGFloat

    init(token: TypographyToken) {
        self.token = token
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: token.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .tracking(token.size * scale * token.trackingEm)
    }

    private var font: Font {
        switch token.face {
        case .rounded:
            // 丸ゴは W4 のまま。`.bold()`・`.fontWeight` を付けない（Q6）
            .custom(Typography.roundedFontName, size: token.size, relativeTo: token.relativeTo)
        case let .system(weight):
            .system(size: token.size * scale, weight: weight)
        }
    }
}

extension View {
    /// 文字のトークン（大きさ・書体・太さ・字間）を当てる。Dynamic Type に追従する
    func appFont(_ token: TypographyToken) -> some View {
        modifier(TypographyModifier(token: token))
    }
}
