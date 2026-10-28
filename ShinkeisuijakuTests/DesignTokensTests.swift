//
//  DesignTokensTests.swift
//  ShinkeisuijakuTests
//
//  デザイントークンが引き継ぎブックの値どおりかを確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import SwiftUI
import Testing
import UIKit

struct DesignTokensTests {
    /// 色を外観ごとに解決し、`0xRRGGBB` に戻す
    private func hex(_ color: Color, style: UIUserInterfaceStyle = .light) -> UInt32 {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (UInt32((red * 255).rounded()) << 16) | (UInt32((green * 255).rounded()) << 8) | UInt32((blue * 255).rounded())
    }

    /// 16 進数から作った色が同じ値に戻る
    @Test
    func hexColorRoundTrips() {
        #expect(hex(Color(hex: 0x2B3140)) == 0x2B3140)
        #expect(hex(Color(hex: 0xFFFFFF)) == 0xFFFFFF)
        #expect(hex(Color(hex: 0x000000)) == 0x000000)
    }

    /// 画面の色はライトとダークで引き継ぎブックの値に切り替わる
    @Test
    func screenColorsSwitchWithAppearance() {
        let expectations = [
            ScreenColor(name: "background", color: Palette.background, light: 0xFDF6EC, dark: 0x1F1A16),
            ScreenColor(name: "surface", color: Palette.surface, light: 0xFFFFFF, dark: 0x2A2420),
            ScreenColor(name: "text", color: Palette.text, light: 0x3A2E25, dark: 0xF3E9DD),
            ScreenColor(name: "muted", color: Palette.muted, light: 0x6B5D52, dark: 0xB3A597),
            ScreenColor(name: "accent", color: Palette.accent, light: 0x2F6BD6, dark: 0x7AA9FF),
            ScreenColor(name: "accentText", color: Palette.accentText, light: 0xFFFFFF, dark: 0x10203A),
            ScreenColor(name: "border", color: Palette.border, light: 0xECDCC8, dark: 0x3D342D)
        ]
        for expectation in expectations {
            #expect(hex(expectation.color, style: .light) == expectation.light, "\(expectation.name) のライト")
            #expect(hex(expectation.color, style: .dark) == expectation.dark, "\(expectation.name) のダーク")
        }
    }

    /// 画面の色 1 つの、引き継ぎブックのライトとダークの値
    private struct ScreenColor {
        let name: String
        let color: Color
        let light: UInt32
        let dark: UInt32
    }

    /// カードの文字の色はダークでも濃い色のまま
    @Test
    func cardInkStaysDarkInDarkMode() {
        #expect(hex(Palette.cardInk, style: .dark) == 0x3A2E25)
        #expect(hex(Palette.cardBack, style: .dark) == 0x8FB7F9)
    }

    /// 画面の面の上に直接描く絵の線（ヒントの目）は、ライトは輪郭線と同じ、ダークは文字の色にして暗い面でも見えるようにする
    @Test
    func artLineOnSurfaceSwitchesWithAppearance() {
        #expect(hex(Palette.artLineOnSurface, style: .light) == 0x2B3140)
        #expect(hex(Palette.artLineOnSurface, style: .dark) == 0xF3E9DD)
        #expect(hex(Palette.artLineOnSurface, style: .light) == hex(Palette.artOutline))
        #expect(hex(Palette.artLineOnSurface, style: .dark) == hex(Palette.text, style: .dark))
    }

    /// 始めに全部見せる時間は、初回クリア前は 4.8 秒、それ以降はペアの数で決まる
    @Test
    func revealAllDurationFollowsHandoffBook() {
        #expect(Motion.revealAllDuration(pairCount: 6, isBeforeFirstClear: false) == 2.6)
        #expect(Motion.revealAllDuration(pairCount: 8, isBeforeFirstClear: false) == 3.0)
        #expect(Motion.revealAllDuration(pairCount: 10, isBeforeFirstClear: false) == 3.4)
        #expect(Motion.revealAllDuration(pairCount: 6, isBeforeFirstClear: true) == 4.8)
        #expect(Motion.revealAllDuration(pairCount: 10, isBeforeFirstClear: true) == 4.8)
    }

    /// 丸ゴの書体が端末に入っている（同梱しないため、名前が違うとシステムの書体に置き換わってしまう）
    @Test
    func roundedFontIsInstalled() {
        #expect(UIFont(name: Typography.roundedFontName, size: 12) != nil)
    }
}
