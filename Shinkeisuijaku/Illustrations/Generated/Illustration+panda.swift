//
//  Illustration+panda.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// パンダ（SVG の `<g id="panda">`）
    static let panda: [IllustrationPart] = [
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 16, y: 20, width: 24, height: 24)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 68, y: 20, width: 24, height: 24)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 18, y: 28, width: 72, height: 64)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 31, y: 44, width: 18, height: 24)).rotated(by: 20, around: CGPoint(x: 40, y: 56)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 59, y: 44, width: 18, height: 24)).rotated(by: -20, around: CGPoint(x: 68, y: 56)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 37.5, y: 51.5, width: 7, height: 7)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 63.5, y: 51.5, width: 7, height: 7)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 48, y: 63.5, width: 12, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 72))
                path.addQuadCurve(to: CGPoint(x: 43, y: 75), control: CGPoint(x: 48, y: 79))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 72))
                path.addQuadCurve(to: CGPoint(x: 65, y: 75), control: CGPoint(x: 60, y: 79))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        )
    ]
}
