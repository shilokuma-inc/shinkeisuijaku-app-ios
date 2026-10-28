#!/usr/bin/env python3
"""絵の SVG（Discussion #4 の Q1 の添付）を、SwiftUI の Path のコードに変換する。

使い方（リポジトリ直下で）:
    python3 Tools/illustrations/convert.py           # Shinkeisuijaku/Illustrations/Generated/ を書き出す
    python3 Tools/illustrations/convert.py --check   # 書き出し済みのコードが SVG と合っているかだけ確かめる

SVG の `<g id="…">`（cat・dog・…・star）を 1 つずつ読み、中の path・circle・ellipse を、塗り・線の色・線の太さ・
線の端の形と一緒に `IllustrationPart` に置き換える。色は Palette の絵の色の名前に置き換え、知らない色や
対応していない要素・命令があれば止まる（見た目が SVG と変わらないようにするため）。
座標は 1 つの図の枠（108×108）の中の値にする（SVG の `<g transform="translate(4 4)">` の分を足す）。
"""

from __future__ import annotations

import argparse
import math
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent / "illustrations.svg"
OUTPUT_DIR = ROOT / "Shinkeisuijaku" / "Illustrations" / "Generated"
SVG_NS = "{http://www.w3.org/2000/svg}"

# SVG の id と、Swift の Picture の case 名・日本語の名前
PICTURES = [
    ("cat", "ネコ"), ("dog", "イヌ"), ("rabbit", "ウサギ"), ("panda", "パンダ"), ("frog", "カエル"),
    ("chick", "ヒヨコ"), ("fox", "キツネ"), ("penguin", "ペンギン"), ("apple", "リンゴ"),
    ("strawberry", "イチゴ"), ("bear", "クマ"), ("suika", "スイカ"), ("star", "ホシ"),
]

# SVG の色と Palette の名前（引き継ぎブックの「絵の色」）
COLORS = {
    "#e53935": "artRed", "#ff8a1f": "artOrange", "#ffc400": "artYellow", "#2ebd6b": "artGreen",
    "#2f7df6": "artBlue", "#ff7fa3": "artPink", "#8d5a36": "artBrown", "#e0a96d": "artTan",
    "#ffffff": "artWhite", "#222733": "artDark", "#8f9bb3": "artGray", "#ff3d6b": "artBerry",
    "#2b3140": "artOutline",
}

# 輪郭線の太さ（Metrics.artOutlineWidth と同じ値）。これと同じ太さはトークンの名前で書き出す
OUTLINE_WIDTH = 2.2


def fail(message: str) -> None:
    raise SystemExit(f"convert.py: {message}")


def number(value: float) -> str:
    """Swift のコードに書く数。整数ならそのまま、小数は余計な 0 を付けない"""
    rounded = round(value, 4)
    if rounded == int(rounded):
        return str(int(rounded))
    return f"{rounded:.4f}".rstrip("0").rstrip(".")


def point(x: float, y: float) -> str:
    return f"CGPoint(x: {number(x)}, y: {number(y)})"


def color(value: str | None) -> str | None:
    if value is None or value == "none":
        return None
    name = COLORS.get(value.lower())
    if name is None:
        fail(f"Palette に無い色です: {value}")
    return f"Palette.{name}"


def parse_translate(transform: str | None) -> tuple[float, float]:
    if not transform:
        return 0.0, 0.0
    match = re.fullmatch(r"\s*translate\(\s*([-\d.]+)[\s,]+([-\d.]+)\s*\)\s*", transform)
    if match is None:
        fail(f"translate 以外の変形には対応していません: {transform}")
    return float(match.group(1)), float(match.group(2))


def parse_rotate(transform: str | None) -> tuple[float, float, float] | None:
    if not transform:
        return None
    match = re.fullmatch(r"\s*rotate\(\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([-\d.]+)\s*\)\s*", transform)
    if match is None:
        fail(f"rotate(角度 x y) 以外の変形には対応していません: {transform}")
    return float(match.group(1)), float(match.group(2)), float(match.group(3))


def tokenize_path(data: str) -> list[str]:
    return re.findall(r"[MLQCAZmlqcaz]|-?\d*\.?\d+(?:e-?\d+)?", data)


def arc_lines(
    start: tuple[float, float], radius: float, large_arc: bool, sweep: bool, end: tuple[float, float]
) -> list[str]:
    """SVG の円弧（rx = ry・回転なし）を、中心と角度の `addArc` にする"""
    (x1, y1), (x2, y2) = start, end
    mid_x, mid_y = (x1 + x2) / 2, (y1 + y2) / 2
    half = math.hypot(x2 - x1, y2 - y1) / 2
    if half == 0:
        fail("始点と終点が同じ円弧には対応していません")
    radius = max(radius, half)
    offset = math.sqrt(max(radius * radius - half * half, 0))
    # 弦の垂直の向き。large_arc と sweep が同じなら反対側に中心を置く（SVG の仕様）
    ux, uy = -(y2 - y1) / (2 * half), (x2 - x1) / (2 * half)
    sign = -1 if large_arc == sweep else 1
    cx, cy = mid_x + sign * offset * ux, mid_y + sign * offset * uy
    start_angle = math.degrees(math.atan2(y1 - cy, x1 - cx))
    end_angle = math.degrees(math.atan2(y2 - cy, x2 - cx))
    # SVG の sweep = 1 は y が下向きの座標で時計回り。SwiftUI の clockwise は y が上向きの座標の向きなので反対になる
    return [
        f"path.addArc(center: {point(cx, cy)}, radius: {number(radius)}, "
        f"startAngle: .degrees({number(start_angle)}), endAngle: .degrees({number(end_angle)}), "
        f"clockwise: {'false' if sweep else 'true'})"
    ]


def path_lines(data: str, dx: float, dy: float) -> list[str]:
    tokens = tokenize_path(data)
    lines: list[str] = []
    index = 0
    command = ""
    current = (0.0, 0.0)

    def take(count: int) -> list[float]:
        nonlocal index
        values = [float(token) for token in tokens[index:index + count]]
        if len(values) != count or any(re.fullmatch(r"[A-Za-z]", t) for t in tokens[index:index + count]):
            fail(f"パスの数が足りません: {data}")
        index += count
        return values

    while index < len(tokens):
        token = tokens[index]
        if re.fullmatch(r"[A-Za-z]", token):
            command = token
            index += 1
            if command.islower():
                fail(f"相対座標の命令には対応していません: {command}")
            if command == "Z":
                lines.append("path.closeSubpath()")
                continue
        if command == "M":
            x, y = take(2)
            current = (x + dx, y + dy)
            lines.append(f"path.move(to: {point(*current)})")
            command = "L"
        elif command == "L":
            x, y = take(2)
            current = (x + dx, y + dy)
            lines.append(f"path.addLine(to: {point(*current)})")
        elif command == "Q":
            cx, cy, x, y = take(4)
            current = (x + dx, y + dy)
            lines.append(f"path.addQuadCurve(to: {point(*current)}, control: {point(cx + dx, cy + dy)})")
        elif command == "C":
            c1x, c1y, c2x, c2y, x, y = take(6)
            current = (x + dx, y + dy)
            lines.append(
                f"path.addCurve(to: {point(*current)}, control1: {point(c1x + dx, c1y + dy)}, "
                f"control2: {point(c2x + dx, c2y + dy)})"
            )
        elif command == "A":
            rx, ry, rotation, large_arc, sweep, x, y = take(7)
            if rx != ry or rotation != 0:
                fail(f"楕円の円弧と回転した円弧には対応していません: {data}")
            end = (x + dx, y + dy)
            lines.extend(arc_lines(current, rx, bool(large_arc), bool(sweep), end))
            current = end
        else:
            fail(f"対応していないパスの命令です: {command}（{data}）")
    return lines


def element_path(element: ET.Element, dx: float, dy: float) -> list[str]:
    tag = element.tag.replace(SVG_NS, "")
    if tag == "path":
        if element.get("transform"):
            fail("変形の付いた path には対応していません")
        return ["Path { path in", *[f"    {line}" for line in path_lines(element.get("d", ""), dx, dy)], "}"]
    if tag in ("circle", "ellipse"):
        cx = float(element.get("cx", "0")) + dx
        cy = float(element.get("cy", "0")) + dy
        if tag == "circle":
            rx = ry = float(element.get("r", "0"))
        else:
            rx, ry = float(element.get("rx", "0")), float(element.get("ry", "0"))
        rect = f"CGRect(x: {number(cx - rx)}, y: {number(cy - ry)}, width: {number(rx * 2)}, height: {number(ry * 2)})"
        rotation = parse_rotate(element.get("transform"))
        if rotation is None:
            return [f"Path(ellipseIn: {rect})"]
        angle, ox, oy = rotation
        return [f"Path(ellipseIn: {rect}).rotated(by: {number(angle)}, around: {point(ox + dx, oy + dy)})"]
    fail(f"対応していない要素です: {tag}")
    return []


def part_lines(element: ET.Element, dx: float, dy: float) -> list[str]:
    fill = color(element.get("fill"))
    stroke = color(element.get("stroke"))
    width = float(element.get("stroke-width", "0")) if stroke else 0
    cap = element.get("stroke-linecap", "butt")
    if cap not in ("butt", "round"):
        fail(f"対応していない線の端です: {cap}")
    join = element.get("stroke-linejoin", "round")
    if join != "round":
        fail(f"丸以外の線のつなぎ目には対応していません: {join}")
    width_code = "Metrics.artOutlineWidth" if width == OUTLINE_WIDTH else number(width)
    path = element_path(element, dx, dy)
    lines = ["IllustrationPart(", f"    path: {path[0]}", *[f"    {line}" for line in path[1:]]]
    lines[-1] += ","
    lines.append(f"    fill: {fill or 'nil'},")
    lines.append(f"    stroke: {stroke or 'nil'},")
    lines.append(f"    lineWidth: {width_code},")
    lines.append(f"    roundCap: {'true' if cap == 'round' else 'false'}")
    lines.append(")")
    return lines


def picture_source(picture: str, name: str, group: ET.Element, dx: float, dy: float) -> str:
    parts = [part_lines(element, dx, dy) for element in group]
    if not parts:
        fail(f"{picture} に図形がありません")
    body: list[str] = []
    for index, part in enumerate(parts):
        if index < len(parts) - 1:
            part[-1] += ","
        body.extend(f"        {line}" for line in part)
    return "\n".join([
        "//",
        f"//  Illustration+{picture}.swift",
        "//  Shinkeisuijaku",
        "//",
        "//  Tools/illustrations/convert.py が Tools/illustrations/illustrations.svg から書き出したコード。手で直さない。",
        "//",
        "",
        "import SwiftUI",
        "",
        "extension IllustrationArt {",
        f"    /// {name}（SVG の `<g id=\"{picture}\">`）",
        f"    static let {picture}: [IllustrationPart] = [",
        *body,
        "    ]",
        "}",
        "",
    ])


def generate() -> dict[Path, str]:
    text = SOURCE.read_text(encoding="utf-8")
    root = ET.fromstring(text)
    parents = {child: parent for parent in root.iter() for child in parent}
    groups = {element.get("id"): element for element in root.iter(f"{SVG_NS}g") if element.get("id")}
    expected = [picture for picture, _ in PICTURES]
    if sorted(groups) != sorted(expected):
        fail(f"SVG の絵の id が想定と違います: {sorted(groups)}")
    files: dict[Path, str] = {}
    for picture, name in PICTURES:
        group = groups[picture]
        # 1 つの図の枠の中の位置（`<g transform="translate(4 4)">`）。シートの並びの変形はその外側なので使わない
        dx, dy = parse_translate(parents[group].get("transform"))
        files[OUTPUT_DIR / f"Illustration+{picture}.swift"] = picture_source(picture, name, group, dx, dy)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="書き出し済みのコードが SVG と合っているかだけ確かめる")
    arguments = parser.parse_args()
    files = generate()
    if arguments.check:
        stale = [path for path, source in files.items() if not path.exists() or path.read_text(encoding="utf-8") != source]
        extra = [path for path in OUTPUT_DIR.glob("*.swift") if path not in files]
        for path in stale + extra:
            print(f"SVG と合っていません: {path.relative_to(ROOT)}", file=sys.stderr)
        return 1 if stale or extra else 0
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for path in OUTPUT_DIR.glob("*.swift"):
        if path not in files:
            path.unlink()
    for path, source in files.items():
        path.write_text(source, encoding="utf-8")
        print(f"書き出しました: {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
