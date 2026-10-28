//
//  HomeView.swift
//  Shinkeisuijaku
//
//  ホーム画面（引き継ぎブックの 10 ページ・仕様書の「画面と遷移」）。
//  上の右に「おうちの方へ」、中央に動物 4 匹のアーチ・色違いのタイトル・説明の 1 行・大きな「あそぶ」、
//  「ほかの あそびかた」の 2 コースとスタンプちょうのボタン、一番下に広告なしの一言。背景は青い水玉。
//  ボタンを押したときの行き先は呼び出し側（`RootView`）が決める。
//

import SwiftUI

/// ホーム画面
struct HomeView: View {
    /// 「あそぶ」で始めるゲーム（前回のコースと難易度。ボタンの下に小さく出す）
    let resumeChoice: GameChoice
    var onPlay: () -> Void = {}
    /// 「ほかの あそびかた」のコースを押したとき（コース選択のダイアログを出す）
    var onChooseCourse: (Course) -> Void = { _ in }
    var onOpenStampBook: () -> Void = {}
    var onOpenParents: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.homeSectionSpacing) {
                HStack {
                    Spacer()
                    parentsButton
                }
                VStack(spacing: Metrics.cardSpacing) {
                    HomeArchView()
                    HomeTitleView()
                    Text("おなじ えを みつけて あそぼう")
                        .appFont(Typography.body)
                        .foregroundStyle(Palette.muted)
                }
                PlayButton(choice: resumeChoice, action: onPlay)
                otherCourses
                Button(action: onOpenStampBook) {
                    Text("スタンプちょう")
                        .appFont(Typography.button)
                        .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                }
                .buttonStyle(SurfaceButtonStyle())
                .accessibilityIdentifier("home.stampBook")
                Spacer(minLength: 0)
                Text("こうこくは でません")
                    .appFont(Typography.note)
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, Metrics.screenHorizontalPadding)
            .padding(.vertical, Metrics.cardSpacing)
            // 画面に入るときは画面の高さいっぱいに広げ、広告なしの一言を一番下に置く（文字を大きくして入らないときだけスクロールする）
            .containerRelativeFrame(.vertical) { height, _ in
                height
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background {
            ZStack {
                Palette.background
                DotPattern(spacing: Metrics.homeDotSpacing, diameter: Metrics.homeDotDiameter, color: Palette.homeBackgroundDot)
            }
            .ignoresSafeArea()
        }
        .accessibilityIdentifier("home")
    }

    /// 上の右の「おうちの方へ」（丸いボタン・高さ 44 以上）
    private var parentsButton: some View {
        Button(action: onOpenParents) {
            Text("おうちの方へ")
                .appFont(Typography.button)
                .foregroundStyle(Palette.text)
                .padding(.horizontal, Metrics.roundButtonHorizontalPadding)
                .frame(minHeight: Metrics.roundButtonMinHeight)
                .background(Palette.surface, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.parents")
    }

    /// 「ほかの あそびかた」の どうぶつ・ひらがな（押すとコース選択）
    private var otherCourses: some View {
        VStack(spacing: Metrics.cardSpacing) {
            Text("ほかの あそびかた")
                .appFont(Typography.noteStrong)
                .foregroundStyle(Palette.muted)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Metrics.cardSpacing) {
                ForEach(Course.allCases, id: \.self) { course in
                    Button {
                        onChooseCourse(course)
                    } label: {
                        Text(course.name)
                            .appFont(Typography.button)
                            .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
                    }
                    .buttonStyle(SurfaceButtonStyle())
                    .accessibilityIdentifier("home.course.\(course.rawValue)")
                }
            }
        }
    }
}

/// 動物 4 匹のアーチ（ネコ・パンダ・キツネ・カエル。引き継ぎブックの 8 ページの「ホームのアーチ」）。真ん中の 2 匹を持ち上げて弧にする
struct HomeArchView: View {
    /// 左から並べる絵
    static let pictures: [Picture] = [.cat, .panda, .fox, .frog]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(Self.pictures.enumerated()), id: \.element) { index, picture in
                let isInner = index != 0 && index != Self.pictures.count - 1
                IllustrationView(picture: picture)
                    .frame(width: Metrics.homeArchPictureSize, height: Metrics.homeArchPictureSize)
                    .padding(.bottom, isInner ? Metrics.homeArchRise : 0)
            }
        }
        .accessibilityHidden(true)
    }
}

/// 色違いのひらがなのタイトル「しんけいすいじゃく」（丸ゴ 32・字間 0.02em。1 字ずつ `Palette.homeTitleColors` の順に色を変える）
struct HomeTitleView: View {
    private static let title = String(localized: "しんけいすいじゃく")

    var body: some View {
        Text(Self.coloredTitle)
            .appFont(Typography.homeTitle)
            .lineLimit(1)
            .minimumScaleFactor(Metrics.homeTitleMinimumScale)
            .accessibilityLabel(Text(verbatim: Self.title))
            .accessibilityAddTraits(.isHeader)
    }

    /// 1 字ずつ色を付けたタイトル
    private static var coloredTitle: AttributedString {
        var text = AttributedString()
        for (index, character) in title.enumerated() {
            var letter = AttributedString(String(character))
            letter.foregroundColor = Palette.homeTitleColors[index % Palette.homeTitleColors.count]
            text += letter
        }
        return text
    }
}

/// 大きな「▶ あそぶ」（強調色の地・高さ 80・角丸 24・下に 5 の影）。下に、始めるコースと難易度を小さく出す
struct PlayButton: View {
    let choice: GameChoice
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: Metrics.cardSpacing) {
                    Image(systemName: "play.fill")
                        .accessibilityHidden(true)
                    Text("あそぶ")
                }
                .appFont(Typography.playButton)
                Text("\(choice.course.name)・\(choice.difficulty.name)")
                    .appFont(Typography.noteStrong)
            }
            .foregroundStyle(Palette.accentText)
            .frame(maxWidth: .infinity, minHeight: Metrics.playButtonHeight)
        }
        .buttonStyle(PlayButtonStyle())
        .accessibilityIdentifier("home.play")
    }
}

/// 大きな「あそぶ」の見た目。押しているあいだは影の分だけ沈める
private struct PlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let offset = configuration.isPressed ? Metrics.playButtonShadowOffsetY : 0
        configuration.label
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Metrics.playButtonCornerRadius))
            .offset(y: offset)
            .background {
                RoundedRectangle(cornerRadius: Metrics.playButtonCornerRadius)
                    .fill(Palette.playButtonShadow)
                    .offset(y: Metrics.playButtonShadowOffsetY)
            }
            .padding(.bottom, Metrics.playButtonShadowOffsetY)
    }
}

/// 撮影モードのホーム。1 回クリアした後のデモの保存（ひらがな・やさしい）で開く（保存は実際の端末に書かない）
struct HomeScreenshotDemoView: View {
    var body: some View {
        HomeView(resumeChoice: GameChoice(course: .hiragana, difficulty: .easy))
    }
}

#Preview {
    HomeScreenshotDemoView()
}
