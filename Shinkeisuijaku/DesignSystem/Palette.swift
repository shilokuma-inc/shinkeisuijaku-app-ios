//
//  Palette.swift
//  Shinkeisuijaku
//
//  引き継ぎブックの 11 ページの `Palette` をそのまま写した色のトークン。
//  画面は色の値を直接書かず、ここの色だけを使う。
//

import SwiftUI
import UIKit

extension UIColor {
    /// `0xRRGGBB` の 16 進数から sRGB の色を作る
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    /// `0xRRGGBB` の 16 進数から sRGB の色を作る
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// ライトとダークで値が違う色。外観の切り替えに合わせて UIKit が色を選び直す
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// アプリで使う色。値は引き継ぎブックの「色」と同じ
enum Palette {
    // 画面の色（ライトとダーク）
    /// 背景。画面の地
    static let background = Color.dynamic(light: 0xFDF6EC, dark: 0x1F1A16)
    /// 面。ボタン・数字の表示の地
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x2A2420)
    /// 文字。本文
    static let text = Color.dynamic(light: 0x3A2E25, dark: 0xF3E9DD)
    /// 補助の文字。説明文・小さな文字
    static let muted = Color.dynamic(light: 0x6B5D52, dark: 0xB3A597)
    /// 強調。主なボタン・「あと◯ペア」の数字
    static let accent = Color.dynamic(light: 0x2F6BD6, dark: 0x7AA9FF)
    /// 強調の上の文字。強調色のボタンの上の文字
    static let accentText = Color.dynamic(light: 0xFFFFFF, dark: 0x10203A)
    /// 境界線。枠の線
    static let border = Color.dynamic(light: 0xECDCC8, dark: 0x3D342D)

    // カードの色（ライトとダークで同じ）
    /// カードの裏の地。白い水玉（`cardBackDot`）を重ねる
    static let cardBack = Color(hex: 0x8FB7F9)
    /// カードの裏の水玉（白・透明度 55%）
    static let cardBackDot = Color(hex: 0xFFFFFF, opacity: 0.55)
    /// 裏の「？」の文字
    static let cardBackText = Color(hex: 0x234FA5)
    /// 文字のカード（ひらがなのカード）の地
    static let cardLetter = Color(hex: 0xFFF3D6)
    /// 絵のカードの地
    static let cardPicture = Color(hex: 0xDCE8F7)
    /// ペアが揃ったカードの地
    static let cardMatched = Color(hex: 0xD8F3DC)
    /// カードの表の文字。ダークでも濃い色のまま
    static let cardInk = Color(hex: 0x3A2E25)

    // 絵の色
    /// 赤。リンゴ
    static let artRed = Color(hex: 0xE53935)
    /// オレンジ。キツネ
    static let artOrange = Color(hex: 0xFF8A1F)
    /// 黄。ヒヨコ・ホシ
    static let artYellow = Color(hex: 0xFFC400)
    /// 緑。カエル・スイカの皮
    static let artGreen = Color(hex: 0x2EBD6B)
    /// 青。ペンギン
    static let artBlue = Color(hex: 0x2F7DF6)
    /// ピンク。ほっぺ・耳の内側・鼻
    static let artPink = Color(hex: 0xFF7FA3)
    /// 茶。イヌの耳・クマ
    static let artBrown = Color(hex: 0x8D5A36)
    /// ベージュ。イヌの顔・クマの口まわり
    static let artTan = Color(hex: 0xE0A96D)
    /// 白。ウサギ・パンダ・目
    static let artWhite = Color(hex: 0xFFFFFF)
    /// 濃い色。目・鼻・口
    static let artDark = Color(hex: 0x222733)
    /// グレー。ネコ
    static let artGray = Color(hex: 0x8F9BB3)
    /// ベリー色。イチゴ
    static let artBerry = Color(hex: 0xFF3D6B)
    /// 輪郭線。図形の輪郭線（太さは `Metrics.artOutlineWidth`）
    static let artOutline = Color(hex: 0x2B3140)
    /// 画面の面（ボタンなど）の上に直接描く絵の線。ライトは輪郭線と同じ、ダークは文字の色にして暗い面でも見えるようにする
    /// （カードの上の絵はカードの色が明るいままなので `artOutline` を使う）
    static let artLineOnSurface = Color.dynamic(light: 0x2B3140, dark: 0xF3E9DD)

    // スタンプ
    /// 銀のふち。パス専用・ふつうをクリアしたスタンプ
    static let stampSilver = Color(hex: 0xAAB4BB)
    /// 銀の地
    static let stampSilverWash = Color(hex: 0xF1F4F6)
    /// 金のふち。パス専用・むずかしいをクリアしたスタンプ
    static let stampGold = Color(hex: 0xE0A800)
    /// 金の地
    static let stampGoldWash = Color(hex: 0xFFF4CC)
    /// 空の枠。まだ手に入れていない枠の点線の丸
    static let stampEmpty = Color(hex: 0xC9BBA8)
    /// パス専用の枠の鍵（引き継ぎブックの 6 ページの見本の明るい灰茶。空の枠の点線より少し濃くする）
    static let stampLock = Color(hex: 0x9C8C7A)
    /// スタンプの影（カードの影と同じ黒・透明度 14%）
    static let stampShadow = Color(hex: 0x000000, opacity: 0.14)
    /// 通常のスタンプの淡い地の、絵の色の濃さ（絵の色をこの透明度で白に重ねる。「絵の色に合う淡い地」）
    static let stampWashOpacity = 0.2

    // 影と幕
    /// カードの影（黒・透明度 14%）
    static let cardShadow = Color(hex: 0x000000, opacity: 0.14)
    /// ダイアログの後ろの暗い幕（黒・透明度 45%）
    static let dialogScrim = Color(hex: 0x000000, opacity: 0.45)
}
