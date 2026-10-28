//
//  Illustration+cat.swift
//  Shinkeisuijaku
//
//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。
//

import SwiftUI

extension IllustrationArt {
    /// ネコ（SVG の `<g id="cat">`）
    static let cat: [IllustrationPart] = [
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 22, y: 48))
                path.addLine(to: CGPoint(x: 28, y: 12))
                path.addLine(to: CGPoint(x: 50, y: 30))
                path.closeSubpath()
            },
            fill: Palette.artGray,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 86, y: 48))
                path.addLine(to: CGPoint(x: 80, y: 12))
                path.addLine(to: CGPoint(x: 58, y: 30))
                path.closeSubpath()
            },
            fill: Palette.artGray,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 29, y: 38))
                path.addLine(to: CGPoint(x: 31, y: 22))
                path.addLine(to: CGPoint(x: 41, y: 31))
                path.closeSubpath()
            },
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 79, y: 38))
                path.addLine(to: CGPoint(x: 77, y: 22))
                path.addLine(to: CGPoint(x: 67, y: 31))
                path.closeSubpath()
            },
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 20, y: 28, width: 68, height: 68)),
            fill: Palette.artGray,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 39, y: 64, width: 30, height: 20)),
            fill: Palette.artWhite,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 36.5, y: 53.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path(ellipseIn: CGRect(x: 62.5, y: 53.5, width: 9, height: 9)),
            fill: Palette.artDark,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 49, y: 67))
                path.addLine(to: CGPoint(x: 59, y: 67))
                path.addLine(to: CGPoint(x: 54, y: 73))
                path.closeSubpath()
            },
            fill: Palette.artPink,
            stroke: Palette.artOutline,
            lineWidth: Metrics.artOutlineWidth,
            roundCap: false
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 73))
                path.addQuadCurve(to: CGPoint(x: 42, y: 76), control: CGPoint(x: 48, y: 80))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 54, y: 73))
                path.addQuadCurve(to: CGPoint(x: 66, y: 76), control: CGPoint(x: 60, y: 80))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2.5,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 18, y: 66))
                path.addLine(to: CGPoint(x: 34, y: 69))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 18, y: 78))
                path.addLine(to: CGPoint(x: 34, y: 74))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 90, y: 66))
                path.addLine(to: CGPoint(x: 74, y: 69))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        ),
        IllustrationPart(
            path: Path { path in
                path.move(to: CGPoint(x: 90, y: 78))
                path.addLine(to: CGPoint(x: 74, y: 74))
            },
            fill: nil,
            stroke: Palette.artDark,
            lineWidth: 2,
            roundCap: true
        )
    ]
}
