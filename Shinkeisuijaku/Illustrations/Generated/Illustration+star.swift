//
//  Illustration+star.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// ホシ（SVG の `<g id="star">`）
    static let star: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 12))
                path.addLine(to: CGPoint(x: 65.76, y: 39.82))
                path.addLine(to: CGPoint(x: 95.85, y: 42.4))
                path.addLine(to: CGPoint(x: 73.02, y: 62.18))
                path.addLine(to: CGPoint(x: 79.86, y: 91.6))
                path.addLine(to: CGPoint(x: 54, y: 76))
                path.addLine(to: CGPoint(x: 28.14, y: 91.6))
                path.addLine(to: CGPoint(x: 34.98, y: 62.18))
                path.addLine(to: CGPoint(x: 12.15, y: 42.4))
                path.addLine(to: CGPoint(x: 42.24, y: 39.82))
                path.closeSubpath()
            },
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 42.5, y: 54.5, width: 7, height: 7)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 58.5, y: 54.5, width: 7, height: 7)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 47, y: 67))
                path.addQuadCurve(to: CGPoint(x: 61, y: 67), control: CGPoint(x: 54, y: 74))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        )
    ]
}
