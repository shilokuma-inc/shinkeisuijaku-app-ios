//
//  Illustration+suika.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// スイカ（SVG の `<g id="suika">`）
    static let suika: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 10, y: 38))
                path.addArc(center: CGPoint(x: 54, y: 38), radius: 44, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                path.closeSubpath()
            },
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 18, y: 38))
                path.addArc(center: CGPoint(x: 54, y: 38), radius: 36, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                path.closeSubpath()
            },
            fill: Palette.artRed,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 33.4, y: 47.8, width: 5.2, height: 8.4)).rotated(by: -20, around: CGPoint(x: 36, y: 52)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 51.4, y: 57.8, width: 5.2, height: 8.4)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 69.4, y: 47.8, width: 5.2, height: 8.4)).rotated(by: 20, around: CGPoint(x: 72, y: 52)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 51.4, y: 43.8, width: 5.2, height: 8.4)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        )
    ]
}
