//
//  Illustration+frog.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// カエル（SVG の `<g id="frog">`）
    static let frog: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 16, y: 38, width: 76, height: 56)),
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 19, y: 21, width: 30, height: 30)),
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 59, y: 21, width: 30, height: 30)),
            fill: Palette.artGreen,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 24, y: 26, width: 20, height: 20)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 64, y: 26, width: 20, height: 20)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 30, y: 32, width: 10, height: 10)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 68, y: 32, width: 10, height: 10)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 18, y: 66, width: 12, height: 12)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 78, y: 66, width: 12, height: 12)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 47, y: 56, width: 4, height: 4)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 57, y: 56, width: 4, height: 4)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 30, y: 70))
                path.addQuadCurve(to: CGPoint(x: 78, y: 70), control: CGPoint(x: 54, y: 90))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 3,
            roundCap: true
        )
    ]
}
