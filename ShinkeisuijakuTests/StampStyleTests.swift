//
//  StampStyleTests.swift
//  ShinkeisuijakuTests
//
//  スタンプの部品の見た目の決まり（引き継ぎブックの 6・7 ページ）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import SwiftUI
import Testing

struct StampStyleTests {
    /// 通常のスタンプの淡い地は、その絵の色から作る（絵の色の対応は引き継ぎブックの「絵の色」）
    @Test
    func regularStampWashFollowsThePictureColor() {
        #expect(StampStyle.mainColor(of: .cat) == Palette.artGray)
        #expect(StampStyle.mainColor(of: .apple) == Palette.artRed)
        #expect(StampStyle.mainColor(of: .penguin) == Palette.artBlue)
        #expect(StampStyle.mainColor(of: .strawberry) == Palette.artBerry)
        #expect(StampStyle.mainColor(of: .bear) == Palette.artBrown)
        #expect(Palette.stampWashOpacity > 0 && Palette.stampWashOpacity < 0.5, "淡い地")
    }

    /// 銀はふつう、金はむずかしいの色（ふちと地）
    @Test
    func rimColorsMatchTheHandoffBook() {
        #expect(StampStyle.rimColors(of: .silver).rim == Palette.stampSilver)
        #expect(StampStyle.rimColors(of: .silver).wash == Palette.stampSilverWash)
        #expect(StampStyle.rimColors(of: .gold).rim == Palette.stampGold)
        #expect(StampStyle.rimColors(of: .gold).wash == Palette.stampGoldWash)
    }

    /// 鍵の形は与えた枠の中に収まる
    @Test
    func lockShapeFitsItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 40, height: 40)
        let bounds = LockShape().path(in: rect).boundingRect
        #expect(rect.insetBy(dx: -0.001, dy: -0.001).contains(bounds))
        #expect(bounds.height > rect.height * 0.9, "つると胴で枠の高さをほぼ使う")
    }
}
