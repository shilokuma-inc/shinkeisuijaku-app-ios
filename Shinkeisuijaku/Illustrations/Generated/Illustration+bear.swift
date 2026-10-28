//
//  Illustration+bear.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// クマ（SVG の `<g id="bear">`）
    static let bear: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 16, y: 20, width: 24, height: 24)),
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 68, y: 20, width: 24, height: 24)),
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 20, y: 26, width: 68, height: 68)),
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 39, y: 61, width: 30, height: 22)),
            fill: Palette.artTan,
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
            path: Path(ellipseIn: CGRect(x: 49, y: 62, width: 10, height: 8)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 70))
                path.addQuadCurve(to: CGPoint(x: 43, y: 73), control: CGPoint(x: 48, y: 77))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 70))
                path.addQuadCurve(to: CGPoint(x: 65, y: 73), control: CGPoint(x: 60, y: 77))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        )
    ]
}
