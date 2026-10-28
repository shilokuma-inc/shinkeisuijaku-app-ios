//
//  IllustrationTests.swift
//  ShinkeisuijakuTests
//
//  SVG から書き出した絵の部品が揃っているかを確かめる（形そのものは見本の画面で添付の画像と見比べる）。
//

import Foundation
@testable import Shinkeisuijaku
import SwiftUI
import Testing

struct IllustrationTests {
    /// SVG の各図の部品の数（path・circle・ellipse の数）。書き出しで部品が抜けたら気づけるようにする
    private let expectedPartCounts: [Picture: Int] = [
        .cat: 15, .dog: 11, .rabbit: 13, .panda: 10, .frog: 12, .chick: 7, .fox: 9,
        .penguin: 11, .apple: 4, .strawberry: 10, .bear: 9, .suika: 6, .star: 4
    ]

    /// 13 種類すべてに部品があり、数が SVG と同じ
    @Test
    func everyPictureHasAllParts() {
        for picture in Picture.allCases {
            #expect(IllustrationArt.parts(for: picture).count == expectedPartCounts[picture], "\(picture)")
        }
    }

    /// 部品は 108×108 の枠の中に収まる（座標のずらし忘れで絵が切れないように）
    @Test
    func partsStayInsideTheCanvas() {
        let canvas = CGRect(x: 0, y: 0, width: Metrics.artCanvasSize, height: Metrics.artCanvasSize)
        for picture in Picture.allCases {
            for part in IllustrationArt.parts(for: picture) {
                #expect(canvas.contains(part.path.boundingRect), "\(picture) の部品が枠の外に出ている: \(part.path.boundingRect)")
            }
        }
    }

    /// どの部品も塗りか線のどちらかを持ち、線のある部品は太さがある
    @Test
    func partsArePaintable() {
        for picture in Picture.allCases {
            for part in IllustrationArt.parts(for: picture) {
                #expect(part.fill != nil || part.stroke != nil, "\(picture)")
                if part.stroke != nil {
                    #expect(part.lineWidth > 0, "\(picture)")
                }
            }
        }
    }

    /// SVG の rotate(角度 x y) と同じく、中心のまわりに回しても中心は動かない
    @Test
    func rotationKeepsTheCenter() {
        let rect = CGRect(x: 10, y: 20, width: 20, height: 40)
        let rotated = Path(ellipseIn: rect).rotated(by: 90, around: CGPoint(x: rect.midX, y: rect.midY))
        #expect(abs(rotated.boundingRect.midX - rect.midX) < 0.001)
        #expect(abs(rotated.boundingRect.midY - rect.midY) < 0.001)
        #expect(abs(rotated.boundingRect.width - rect.height) < 0.001)
    }

    /// 正の角度は、SVG と同じく画面の上で時計回り（右向きの線を 90 度回すと下向きになる）
    @Test
    func positiveRotationIsClockwiseOnScreen() {
        var line = Path()
        line.move(to: CGPoint(x: 50, y: 50))
        line.addLine(to: CGPoint(x: 60, y: 50))
        let rotated = line.rotated(by: 90, around: CGPoint(x: 50, y: 50)).boundingRect
        #expect(abs(rotated.minY - 50) < 0.001)
        #expect(abs(rotated.maxY - 60) < 0.001)
        #expect(abs(rotated.midX - 50) < 0.001)
    }

    /// 円弧の向き: スイカの皮は下に膨らむ半円（上の切り口の y = 38 から、下へ半径 44 まで）
    @Test
    func suikaArcBulgesDownward() throws {
        let rind = try #require(IllustrationArt.parts(for: .suika).first).path.boundingRect
        #expect(abs(rind.minY - 38) < 0.001)
        #expect(abs(rind.maxY - 82) < 0.001)
        #expect(abs(rind.minX - 10) < 0.001)
        #expect(abs(rind.maxX - 98) < 0.001)
    }

    /// ヒントの目は 2 つの目（白目・黒目・光・眉）で、横長の枠に収まり、絵と同じ輪郭線を使う
    @Test
    func hintEyesFitTheirCanvas() {
        let parts = IllustrationArt.hintEyes
        #expect(parts.count == 8)
        let canvas = CGRect(origin: .zero, size: IllustrationArt.hintEyesCanvasSize)
        for part in parts {
            #expect(canvas.contains(part.path.boundingRect), "目の部品が枠の外に出ている: \(part.path.boundingRect)")
        }
        #expect(parts.filter { $0.lineWidth == Metrics.artOutlineWidth }.count == 4)
    }
}
