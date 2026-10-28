//
//  Illustration+dog.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// イヌ（SVG の `<g id="dog">`）
    static let dog: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 13, y: 29, width: 26, height: 50)).rotated(by: 12, around: CGPoint(x: 26, y: 54)),
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 69, y: 29, width: 26, height: 50)).rotated(by: -12, around: CGPoint(x: 82, y: 54)),
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 22, y: 27, width: 64, height: 64)),
            fill: Palette.artTan,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 36, y: 59, width: 36, height: 26)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 49, y: 76, width: 10, height: 12)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 47, y: 59, width: 14, height: 10)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 37.5, y: 47.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 61.5, y: 47.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 69))
                path.addLine(to: CGPoint(x: 54, y: 74))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 74))
                path.addQuadCurve(to: CGPoint(x: 44, y: 76), control: CGPoint(x: 48, y: 80))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 74))
                path.addQuadCurve(to: CGPoint(x: 64, y: 76), control: CGPoint(x: 60, y: 80))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        )
    ]
}
