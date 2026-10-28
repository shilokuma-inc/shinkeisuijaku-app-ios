//
//  Illustration+fox.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// キツネ（SVG の `<g id="fox">`）
    static let fox: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 20, y: 50))
                path.addLine(to: CGPoint(x: 26, y: 10))
                path.addLine(to: CGPoint(x: 50, y: 30))
                path.closeSubpath()
            },
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 88, y: 50))
                path.addLine(to: CGPoint(x: 82, y: 10))
                path.addLine(to: CGPoint(x: 58, y: 30))
                path.closeSubpath()
            },
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 28, y: 38))
                path.addLine(to: CGPoint(x: 30, y: 20))
                path.addLine(to: CGPoint(x: 42, y: 31))
                path.closeSubpath()
            },
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 80, y: 38))
                path.addLine(to: CGPoint(x: 78, y: 20))
                path.addLine(to: CGPoint(x: 66, y: 31))
                path.closeSubpath()
            },
            fill: Palette.artBrown,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 94))
                path.addLine(to: CGPoint(x: 16, y: 56))
                path.addQuadCurve(to: CGPoint(x: 32, y: 38), control: CGPoint(x: 14, y: 40))
                path.addQuadCurve(to: CGPoint(x: 76, y: 38), control: CGPoint(x: 54, y: 34))
                path.addQuadCurve(to: CGPoint(x: 92, y: 56), control: CGPoint(x: 94, y: 40))
                path.closeSubpath()
            },
            fill: Palette.artOrange,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 94))
                path.addLine(to: CGPoint(x: 18, y: 58))
                path.addQuadCurve(to: CGPoint(x: 54, y: 70), control: CGPoint(x: 40, y: 60))
                path.addQuadCurve(to: CGPoint(x: 90, y: 58), control: CGPoint(x: 68, y: 60))
                path.closeSubpath()
            },
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 36, y: 50, width: 8, height: 8)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 64, y: 50, width: 8, height: 8)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 49.5, y: 84.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        )
    ]
}
