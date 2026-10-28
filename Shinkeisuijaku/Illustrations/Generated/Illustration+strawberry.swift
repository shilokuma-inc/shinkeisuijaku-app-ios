//
//  Illustration+strawberry.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// イチゴ（SVG の `<g id="strawberry">`）
    static let strawberry: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 94))
                path.addCurve(to: CGPoint(x: 22, y: 40), control1: CGPoint(x: 24, y: 78), control2: CGPoint(x: 14, y: 52))
                path.addCurve(to: CGPoint(x: 86, y: 40), control1: CGPoint(x: 32, y: 28), control2: CGPoint(x: 76, y: 28))
                path.addCurve(to: CGPoint(x: 54, y: 94), control1: CGPoint(x: 94, y: 52), control2: CGPoint(x: 84, y: 78))
                path.closeSubpath()
            },
            fill: Palette.artBerry,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 35.6, y: 48.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 53.6, y: 44.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 69.6, y: 50.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 29.6, y: 62.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 45.6, y: 60.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 61.6, y: 64.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 51.6, y: 78.2, width: 4.8, height: 7.6)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 36))
                path.addLine(to: CGPoint(x: 38, y: 24))
                path.addLine(to: CGPoint(x: 44, y: 37))
                path.addLine(to: CGPoint(x: 28, y: 34))
                path.addLine(to: CGPoint(x: 42, y: 44))
                path.addLine(to: CGPoint(x: 54, y: 40))
                path.addLine(to: CGPoint(x: 66, y: 44))
                path.addLine(to: CGPoint(x: 80, y: 34))
                path.addLine(to: CGPoint(x: 64, y: 37))
                path.addLine(to: CGPoint(x: 70, y: 24))
                path.closeSubpath()
            },
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 34))
                path.addLine(to: CGPoint(x: 54, y: 20))
            },
            fill: nil,
            stroke: Palette.artGreen,
            lineWidth: 4,
            roundCap: true
        )
    ]
}
