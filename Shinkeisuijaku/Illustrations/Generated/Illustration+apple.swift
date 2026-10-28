//
//  Illustration+apple.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// リンゴ（SVG の `<g id="apple">`）
    static let apple: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 32))
                path.addCurve(to: CGPoint(x: 16, y: 60), control1: CGPoint(x: 34, y: 18), control2: CGPoint(x: 12, y: 34))
                path.addCurve(to: CGPoint(x: 54, y: 90), control1: CGPoint(x: 19, y: 82), control2: CGPoint(x: 36, y: 96))
                path.addCurve(to: CGPoint(x: 92, y: 60), control1: CGPoint(x: 72, y: 96), control2: CGPoint(x: 89, y: 82))
                path.addCurve(to: CGPoint(x: 54, y: 32), control1: CGPoint(x: 96, y: 34), control2: CGPoint(x: 74, y: 18))
                path.closeSubpath()
            },
            fill: Palette.artRed,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 28, y: 47, width: 8, height: 18)).rotated(by: 20, around: CGPoint(x: 32, y: 56)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 32))
                path.addQuadCurve(to: CGPoint(x: 58, y: 12), control: CGPoint(x: 54, y: 20))
            },
            fill: nil,
            stroke: Palette.artBrown,
            lineWidth: 5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 58, y: 24))
                path.addQuadCurve(to: CGPoint(x: 88, y: 20), control: CGPoint(x: 74, y: 10))
                path.addQuadCurve(to: CGPoint(x: 58, y: 24), control: CGPoint(x: 74, y: 34))
                path.closeSubpath()
            },
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        )
    ]
}
