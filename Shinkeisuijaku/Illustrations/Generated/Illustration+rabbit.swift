//
//  Illustration+rabbit.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// ウサギ（SVG の `<g id="rabbit">`）
    static let rabbit: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 30, y: 6, width: 20, height: 48)).rotated(by: -8, around: CGPoint(x: 40, y: 30)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 58, y: 6, width: 20, height: 48)).rotated(by: 8, around: CGPoint(x: 68, y: 30)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 35, y: 14, width: 10, height: 34)).rotated(by: -8, around: CGPoint(x: 40, y: 31)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 63, y: 14, width: 10, height: 34)).rotated(by: 8, around: CGPoint(x: 68, y: 31)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 25, y: 39, width: 58, height: 58)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 29, y: 71, width: 10, height: 10)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 69, y: 71, width: 10, height: 10)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 40, y: 62, width: 8, height: 8)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 60, y: 62, width: 8, height: 8)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 50, y: 71, width: 8, height: 6)),
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 77))
                path.addLine(to: CGPoint(x: 54, y: 80))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 80))
                path.addQuadCurve(to: CGPoint(x: 46, y: 81), control: CGPoint(x: 49, y: 84))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 80))
                path.addQuadCurve(to: CGPoint(x: 62, y: 81), control: CGPoint(x: 59, y: 84))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        )
    ]
}
