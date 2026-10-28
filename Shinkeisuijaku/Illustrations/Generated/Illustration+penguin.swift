//
//  Illustration+penguin.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// ペンギン（SVG の `<g id="penguin">`）
    static let penguin: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 17, y: 50, width: 14, height: 32)).rotated(by: 20, around: CGPoint(x: 24, y: 66)),
            fill: Palette.artBlue,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 77, y: 50, width: 14, height: 32)).rotated(by: -20, around: CGPoint(x: 84, y: 66)),
            fill: Palette.artBlue,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 33, y: 94, width: 18, height: 8)),
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 57, y: 94, width: 18, height: 8)),
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 24, y: 26, width: 60, height: 72)),
            fill: Palette.artBlue,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 34, y: 48, width: 40, height: 48)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 38, y: 34, width: 12, height: 12)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 58, y: 34, width: 12, height: 12)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 42, y: 38, width: 6, height: 6)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 60, y: 38, width: 6, height: 6)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 47, y: 49))
                path.addLine(to: CGPoint(x: 61, y: 49))
                path.addLine(to: CGPoint(x: 54, y: 59))
                path.closeSubpath()
            },
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        )
    ]
}
