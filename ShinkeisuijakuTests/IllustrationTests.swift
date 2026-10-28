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
}
