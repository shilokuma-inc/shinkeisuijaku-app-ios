//
//  DesignTokenCatalogView.swift
//  Shinkeisuijaku
//
//  デザイントークンを並べた見本の画面。撮影モード（`ScreenshotDemo`）と Preview で開き、
//  引き継ぎブックの値どおりかを見比べるために使う。アプリの通常の画面からは開かない。
//

import SwiftUI

/// デザイントークンの見本。色のページと、文字・寸法・動きのページの 2 つ
struct DesignTokenCatalogView: View {
    /// 見本のページ
    enum Page {
        /// 画面・カード・絵・スタンプの色
        case colors
        /// 文字・寸法・動き
        case typeAndMetrics
    }

    let page: Page

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.screenHorizontalPadding) {
                switch page {
                case .colors:
                    colorSections
                case .typeAndMetrics:
                    typographySection
                    metricsSection
                    motionSection
                }
            }
            .padding(.horizontal, Metrics.screenHorizontalPadding)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.text)
    }

    // MARK: - 色

    @ViewBuilder private var colorSections: some View {
        swatchSection("画面の色（ライトとダーク）", swatches: [
            ("background", Palette.background), ("surface", Palette.surface), ("text", Palette.text),
            ("muted", Palette.muted), ("accent", Palette.accent), ("accentText", Palette.accentText),
            ("border", Palette.border)
        ])
        swatchSection("カードの色", swatches: [
            ("cardBack", Palette.cardBack), ("cardBackText", Palette.cardBackText), ("cardLetter", Palette.cardLetter),
            ("cardPicture", Palette.cardPicture), ("cardMatched", Palette.cardMatched), ("cardInk", Palette.cardInk)
        ])
        swatchSection("絵の色", swatches: [
            ("artRed", Palette.artRed), ("artOrange", Palette.artOrange), ("artYellow", Palette.artYellow),
            ("artGreen", Palette.artGreen), ("artBlue", Palette.artBlue), ("artPink", Palette.artPink),
            ("artBrown", Palette.artBrown), ("artTan", Palette.artTan), ("artWhite", Palette.artWhite),
            ("artDark", Palette.artDark), ("artGray", Palette.artGray), ("artBerry", Palette.artBerry),
            ("artOutline", Palette.artOutline)
        ])
        swatchSection("スタンプ", swatches: [
            ("stampSilver", Palette.stampSilver), ("stampSilverWash", Palette.stampSilverWash),
            ("stampGold", Palette.stampGold), ("stampGoldWash", Palette.stampGoldWash), ("stampEmpty", Palette.stampEmpty)
        ])
    }

    private func swatchSection(_ title: LocalizedStringKey, swatches: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text(title)
                .appFont(Typography.dialogTitle)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Metrics.cardSpacing), count: Metrics.cardColumns),
                spacing: Metrics.cardSpacing
            ) {
                ForEach(swatches, id: \.0) { name, color in
                    VStack(spacing: Metrics.pairCountVerticalPadding) {
                        RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                            .fill(color)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                                    .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                            }
                        Text(verbatim: name)
                            .appFont(Typography.note)
                            .foregroundStyle(Palette.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(Metrics.textMinimumScale)
                    }
                }
            }
        }
    }

    // MARK: - 文字

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text("文字")
                .appFont(Typography.dialogTitle)
            Text("しんけいすいじゃく")
                .appFont(Typography.homeTitle)
            Text("▶ あそぶ")
                .appFont(Typography.playButton)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("あと")
                    .appFont(Typography.pairCountLabel)
                Text(verbatim: "6")
                    .appFont(Typography.pairCountNumber)
                    .foregroundStyle(Palette.accent)
                Text("ペア")
                    .appFont(Typography.pairCountLabel)
            }
            Text("どれで あそぶ？")
                .appFont(Typography.dialogTitle)
            HStack(alignment: .firstTextBaseline) {
                Text("やさしい")
                    .appFont(Typography.difficultyButton)
                Text("6ペア")
                    .appFont(Typography.difficultyPairs)
                    .foregroundStyle(Palette.muted)
            }
            Text("ボタンの文字（15・700）")
                .appFont(Typography.button)
            Text("主なボタンの文字（15・800）")
                .appFont(Typography.primaryButton)
            Text("説明文（14・400）")
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
            Text("小さな注記（12・400）")
                .appFont(Typography.note)
                .foregroundStyle(Palette.muted)
            Text("小さな注記（12・700）")
                .appFont(Typography.noteStrong)
                .foregroundStyle(Palette.muted)
            cardTextSamples
        }
    }

    /// カードの短辺に対する割合で決まる文字（裏の「？」・ひらがな・揃うと現れる言葉）
    private var cardTextSamples: some View {
        let side = Metrics.stampBookMaxDiameter
        return HStack(spacing: Metrics.cardSpacing) {
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                .fill(Palette.cardBack)
                .overlay {
                    Text(verbatim: "？")
                        .font(Typography.cardQuestion(shortSide: side))
                        .foregroundStyle(Palette.cardBackText)
                }
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                .fill(Palette.cardLetter)
                .overlay {
                    Text(verbatim: "ね")
                        .font(Typography.cardLetter(shortSide: side))
                        .foregroundStyle(Palette.cardInk)
                }
            RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
                .fill(Palette.cardMatched)
                .overlay(alignment: .bottom) {
                    Text(verbatim: "ねこ")
                        .font(Typography.cardWord(shortSide: side))
                        .foregroundStyle(Palette.cardInk)
                        .padding(.bottom, Metrics.pairCountVerticalPadding)
                }
        }
        .frame(width: side * 3 + Metrics.cardSpacing * 2, height: side)
        .shadow(color: Palette.cardShadow, radius: 0, y: Metrics.cardShadowOffsetY)
    }

    // MARK: - 寸法

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text("寸法")
                .appFont(Typography.dialogTitle)
            Text("▶ あそぶ")
                .appFont(Typography.playButton)
                .foregroundStyle(Palette.accentText)
                .frame(maxWidth: .infinity, minHeight: Metrics.playButtonHeight)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metrics.playButtonCornerRadius))
                .shadow(color: Palette.cardShadow, radius: 0, y: Metrics.playButtonShadowOffsetY)
            Text("ホームにもどる")
                .appFont(Typography.button)
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius)
                        .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                }
            HStack {
                Text("おうちの方へ")
                    .appFont(Typography.button)
                    .padding(.horizontal, Metrics.screenHorizontalPadding)
                    .frame(minHeight: Metrics.roundButtonMinHeight)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.capsuleCornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.capsuleCornerRadius)
                            .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                    }
                Text("あと 6 ペア")
                    .appFont(Typography.pairCountLabel)
                    .padding(.vertical, Metrics.pairCountVerticalPadding)
                    .padding(.horizontal, Metrics.pairCountHorizontalPadding)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius)
                            .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                    }
            }
            HStack(spacing: Metrics.screenHorizontalPadding) {
                Circle()
                    .fill(Palette.stampSilverWash)
                    .overlay { Circle().stroke(Palette.stampSilver, lineWidth: Metrics.stampRimWidth) }
                    .frame(width: Metrics.stampBookMaxDiameter, height: Metrics.stampBookMaxDiameter)
                Circle()
                    .fill(Palette.stampGoldWash)
                    .overlay { Circle().stroke(Palette.stampGold, lineWidth: Metrics.stampRimWidth) }
                    .frame(width: Metrics.stampBookMaxDiameter, height: Metrics.stampBookMaxDiameter)
            }
        }
    }

    // MARK: - 動き

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: Metrics.pairCountVerticalPadding) {
            Text("動き・振動（秒）")
                .appFont(Typography.dialogTitle)
            ForEach(motionRows, id: \.0) { name, value in
                HStack {
                    Text(verbatim: name)
                        .appFont(Typography.body)
                    Spacer()
                    Text(value, format: .number)
                        .appFont(Typography.noteStrong)
                        .foregroundStyle(Palette.muted)
                }
            }
        }
    }

    private var motionRows: [(String, Double)] {
        [
            ("flipDuration", Motion.flipDuration), ("matchDelay", Motion.matchDelay),
            ("matchScale", Double(Motion.matchScale)), ("mismatchDelay", Motion.mismatchDelay),
            ("revealAllSixPairs", Motion.revealAllSixPairs), ("revealAllEightPairs", Motion.revealAllEightPairs),
            ("revealAllTenPairs", Motion.revealAllTenPairs),
            ("revealAllBeforeFirstClear", Motion.revealAllBeforeFirstClear), ("hintDuration", Motion.hintDuration),
            ("clearDialogDelay", Motion.clearDialogDelay), ("matchPulse", HapticTokens.matchPulseDuration),
            ("clearPulse × 2", HapticTokens.clearPulseDuration), ("clearPulseGap", HapticTokens.clearPulseGap)
        ]
    }
}

#Preview("色") {
    DesignTokenCatalogView(page: .colors)
}

#Preview("文字・寸法・動き") {
    DesignTokenCatalogView(page: .typeAndMetrics)
}
