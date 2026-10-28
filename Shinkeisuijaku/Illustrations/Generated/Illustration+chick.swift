//
//  Illustration+chick.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// ヒヨコ（SVG の `<g id="chick">`）
    static let chick: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 20, y: 26, width: 68, height: 68)),
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 46, y: 32))
                path.addQuadCurve(to: CGPoint(x: 52, y: 24), control: CGPoint(x: 46, y: 14))
                path.addQuadCurve(to: CGPoint(x: 60, y: 24), control: CGPoint(x: 56, y: 10))
                path.addQuadCurve(to: CGPoint(x: 64, y: 32), control: CGPoint(x: 66, y: 14))
                path.closeSubpath()
            },
            fill: Palette.artYellow,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 46, y: 62))
                path.addLine(to: CGPoint(x: 62, y: 62))
                path.addLine(to: CGPoint(x: 54, y: 72))
                path.closeSubpath()
            },
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 37.5, y: 49.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 61.5, y: 49.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 27, y: 61, width: 10, height: 10)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 71, y: 61, width: 10, height: 10)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        )
    ]
}
