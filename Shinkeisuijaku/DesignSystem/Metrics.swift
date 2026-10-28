//
//  Metrics.swift
//  Shinkeisuijaku
//
//  引き継ぎブックの「寸法と角丸」を写した寸法のトークン（単位は pt）。
//  画面は余白・角丸・高さ・影の数値を直接書かず、ここの値だけを使う。
//

import CoreGraphics

/// アプリで使う寸法。値は引き継ぎブックの「寸法と角丸」と同じ
enum Metrics {
    // 画面の余白
    /// ゲームの画面の左右の余白
    static let gameHorizontalPadding: CGFloat = 10
    /// ホーム・スタンプちょうの左右の余白
    static let screenHorizontalPadding: CGFloat = 16

    // カード
    /// カードの列の数
    static let cardColumns = 4
    /// カードどうしのすき間（縦横とも）
    static let cardSpacing: CGFloat = 8
    /// カードの角丸
    static let cardCornerRadius: CGFloat = 10
    /// カードの影の下へのずれ（色は `Palette.cardShadow`）
    static let cardShadowOffsetY: CGFloat = 2
    /// カードの影のぼかし（引き継ぎブックは「下へ 2」だけなので、ぼかさない）
    static let cardShadowRadius: CGFloat = 0
    /// カードの裏の水玉の間隔（色は `Palette.cardBackDot`）
    static let cardBackDotSpacing: CGFloat = 18
    /// カードの裏の水玉の直径（引き継ぎブックに無いので、間隔の 3 分の 1 にした）
    static let cardBackDotDiameter: CGFloat = 6
    /// 表のカードの絵の大きさ（カードの短辺に対する割合）
    static let cardPictureRatio: CGFloat = 0.62
    /// ペアが揃って言葉が現れたときの絵の大きさ（カードの短辺に対する割合。下に言葉を置く分だけ小さくする）
    static let cardMatchedPictureRatio: CGFloat = 0.5

    // ボタン
    /// 大きな「あそぶ」の高さ
    static let playButtonHeight: CGFloat = 80
    /// 大きな「あそぶ」の角丸
    static let playButtonCornerRadius: CGFloat = 24
    /// 大きな「あそぶ」の下の影のずれ
    static let playButtonShadowOffsetY: CGFloat = 5
    /// 通常のボタンの高さ
    static let buttonHeight: CGFloat = 52
    /// 通常のボタンの角丸
    static let buttonCornerRadius: CGFloat = 14
    /// 境界線の太さ（ボタン・「あと◯ペア」の表示）
    static let borderWidth: CGFloat = 1
    /// 丸いボタン（おうちの方へ）の高さの下限
    static let roundButtonMinHeight: CGFloat = 44
    /// 完全な丸の角丸（引き継ぎブックの 999）
    static let capsuleCornerRadius: CGFloat = 999
    /// ヒントのボタンの目のアイコンの高さ
    static let hintIconHeight: CGFloat = 22
    /// 押しているあいだのボタンの透明度（引き継ぎブックに無いので、押したと分かる程度にした）
    static let pressedOpacity: Double = 0.7
    /// タップできる大きさの下限（すべてのボタン）
    static let minTapTarget: CGFloat = 44

    // 「あと◯ペア」の表示
    /// 角丸
    static let pairCountCornerRadius: CGFloat = 12
    /// 内側の上下の余白
    static let pairCountVerticalPadding: CGFloat = 6
    /// 内側の左右の余白
    static let pairCountHorizontalPadding: CGFloat = 12

    // ダイアログ（色は `Palette.surface`、後ろの幕は `Palette.dialogScrim`）
    /// 幅の上限
    static let dialogMaxWidth: CGFloat = 320
    /// 角丸
    static let dialogCornerRadius: CGFloat = 22
    /// 内側の上下の余白
    static let dialogVerticalPadding: CGFloat = 24
    /// 内側の左右の余白
    static let dialogHorizontalPadding: CGFloat = 20

    // スタンプ
    /// スタンプちょうのスタンプの直径の下限
    static let stampBookMinDiameter: CGFloat = 72
    /// スタンプちょうのスタンプの直径の上限
    static let stampBookMaxDiameter: CGFloat = 80
    /// スタンプちょうのスタンプの影（引き継ぎブックの「影 3」。見本の見た目から、ぼかさずに下へ 3 ずらす影と読んだ）
    static let stampShadowOffsetY: CGFloat = 3
    /// スタンプの影のぼかし（ぼかさない）
    static let stampShadowRadius: CGFloat = 0
    /// クリア画面のスタンプの直径
    static let clearStampDiameter: CGFloat = 124
    /// クリア画面のスタンプのかたむき（度）
    static let clearStampRotationDegrees: Double = 8
    /// クリア画面のスタンプの点線の青いふちの太さ（色は `Palette.accent`）
    static let clearStampBorderWidth: CGFloat = 3
    /// 銀と金のスタンプのふちの太さ
    static let stampRimWidth: CGFloat = 5
    /// まだのスタンプとパス専用の鍵の点線の太さ（引き継ぎブックに無いので、見本の見た目から決めた）
    static let stampDashedLineWidth: CGFloat = 2.5
    /// 点線の線の長さと間（まだのスタンプ・パス専用の鍵・クリア画面のふち）
    static let stampDash: [CGFloat] = [7, 5]
    /// クリア画面のスタンプの、点線の青いふちとスタンプのすき間
    static let clearStampRingGap: CGFloat = 6
    /// スタンプの中の絵の大きさ（スタンプの直径に対する割合）
    static let stampPictureRatio: CGFloat = 0.66
    /// パス専用の鍵の大きさ（スタンプの直径に対する割合）
    static let stampLockRatio: CGFloat = 0.42

    // 絵
    /// 絵の元の枠の大きさ（SVG の 1 つの図の幅と高さ）
    static let artCanvasSize: CGFloat = 108
    /// 絵の輪郭線の太さ（枠が `artCanvasSize` のときの値。色は `Palette.artOutline`）
    static let artOutlineWidth: CGFloat = 2.2
}
