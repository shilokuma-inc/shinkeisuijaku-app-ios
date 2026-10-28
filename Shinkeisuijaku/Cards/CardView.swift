//
//  CardView.swift
//  Shinkeisuijaku
//
//  カードの部品。裏・文字・絵・そろった の 4 つの状態と、めくり・揃ったときの動き（引き継ぎブックの 6・9 ページ）。
//  見た目はデザイントークンと絵の部品だけで作る。押したときの処理と読み上げは、使う側（プレイ画面）で付ける。
//

import SwiftUI

/// カードの見た目の決まり（View から切り離して確かめられるようにする）
struct CardAppearance: Equatable {
    /// カードの地の色の種類
    enum Background: Equatable {
        case back
        case letter
        case picture
        case matched
    }

    let face: Card.Face
    let isFaceUp: Bool
    /// 揃ったときの見た目（緑の地・言葉）にするか。揃ってから少し遅れて true にする
    let showsMatched: Bool

    /// 地の色の種類
    var background: Background {
        guard isFaceUp else {
            return .back
        }
        if showsMatched {
            return .matched
        }
        switch face {
        case .letter: return .letter
        case .picture: return .picture
        }
    }

    /// 地の色
    var backgroundColor: Color {
        switch background {
        case .back: Palette.cardBack
        case .letter: Palette.cardLetter
        case .picture: Palette.cardPicture
        case .matched: Palette.cardMatched
        }
    }

    /// 揃ったときに現れる言葉（ひらがなコースの絵のカードだけ）
    var word: String? {
        guard isFaceUp, showsMatched, case let .picture(_, word) = face else {
            return nil
        }
        return word
    }

    /// めくっている途中の角度で、表を描くか（0 で裏・180 で表。半分の 90 度からは表）。
    /// 裏を描いているあいだは表の中身を描かないので、裏のカードの中身は見た目にも読み上げにも出ない
    static func showsFront(atAngle angle: Double) -> Bool {
        angle >= Motion.flipAngleDegrees / 2
    }
}

/// カード 1 枚。与えられた大きさいっぱいに描き、めくり・揃ったときの動きを付ける
struct CardView: View {
    let face: Card.Face
    /// 表を見せるか（めくった・揃った・全部見せている・ヒント）
    let isFaceUp: Bool
    /// ペアが揃ったか
    let isMatched: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 揃ったときの見た目にしたか（揃ってから `Motion.matchDelay` だけ遅れて変わる。初めから揃っているカードは遅らせない）
    @State private var showsMatched: Bool
    /// 揃ったときのふくらみ（一度ふくらんで元に戻る）
    @State private var matchPulse = false

    init(face: Card.Face, isFaceUp: Bool, isMatched: Bool) {
        self.face = face
        self.isFaceUp = isFaceUp
        self.isMatched = isMatched
        _showsMatched = State(initialValue: isMatched)
    }

    var body: some View {
        let motion = MotionPolicy(reduceMotion: reduceMotion)
        GeometryReader { proxy in
            let shortSide = min(proxy.size.width, proxy.size.height)
            let appearance = CardAppearance(face: face, isFaceUp: isFaceUp, showsMatched: showsMatched)
            Color.clear
                .modifier(
                    CardFlip(
                        angle: isFaceUp ? Motion.flipAngleDegrees : 0,
                        back: { CardBackSide(shortSide: shortSide) },
                        front: { CardFrontSide(appearance: appearance, shortSide: shortSide) }
                    )
                )
                .animation(motion.flipAnimation, value: isFaceUp)
        }
        .scaleEffect(matchPulse && motion.pulsesOnMatch ? Motion.matchScale : 1)
        .shadow(color: Palette.cardShadow, radius: Metrics.cardShadowRadius, y: Metrics.cardShadowOffsetY)
        // 揃ったら少しおいて緑にする。待つあいだに画面を離れたら（ゲームが変わったら）、待つのをやめる
        .task(id: isMatched) {
            await updateMatched(isMatched, motion: motion)
        }
    }

    /// 揃ったら `Motion.matchDelay` おいて緑にし、ふくらんで戻す。
    /// 「視差効果を減らす」でも同じだけ待つが、ふくらまずに切り替えるだけ（`MotionPolicy`）
    private func updateMatched(_ matched: Bool, motion: MotionPolicy) async {
        guard matched else {
            showsMatched = false
            return
        }
        guard !showsMatched else {
            return
        }
        try? await Task.sleep(for: .seconds(motion.matchDelay))
        guard !Task.isCancelled else {
            return
        }
        guard motion.pulsesOnMatch else {
            showsMatched = true
            return
        }
        withAnimation(.easeOut(duration: Motion.matchPulseDuration)) {
            showsMatched = true
            matchPulse = true
        } completion: {
            withAnimation(.easeIn(duration: Motion.matchPulseDuration)) {
                matchPulse = false
            }
        }
    }
}

/// Y 軸まわりに回す。90 度を過ぎたら表を描く（裏から表へ 180 度）
private struct CardFlip<Back: View, Front: View>: ViewModifier, Animatable {
    /// 0 で裏、180 で表
    var angle: Double
    let back: () -> Back
    let front: () -> Front

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        ZStack {
            if CardAppearance.showsFront(atAngle: angle) {
                // 表は裏返しに見えないよう、さらに半回転しておく
                front()
                    .rotation3DEffect(.degrees(Motion.flipAngleDegrees), axis: (x: 0, y: 1, z: 0))
            } else {
                back()
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
    }
}

/// カードの裏: 青い地に白い水玉と「？」
private struct CardBackSide: View {
    let shortSide: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
            .fill(Palette.cardBack)
            .overlay {
                DotPattern(spacing: Metrics.cardBackDotSpacing, diameter: Metrics.cardBackDotDiameter, color: Palette.cardBackDot)
            }
            .overlay {
                Text(verbatim: "？")
                    .font(Typography.cardQuestion(shortSide: shortSide))
                    .foregroundStyle(Palette.cardBackText)
            }
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    }
}

/// カードの表: 文字か絵。揃ったら緑の地にし、ひらがなコースの絵のカードには言葉を出す
private struct CardFrontSide: View {
    let appearance: CardAppearance
    let shortSide: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: Metrics.cardCornerRadius)
            .fill(appearance.backgroundColor)
            .overlay {
                switch appearance.face {
                case let .letter(letter):
                    Text(verbatim: letter)
                        .font(Typography.cardLetter(shortSide: shortSide))
                        .foregroundStyle(Palette.cardInk)
                case let .picture(picture, _):
                    VStack(spacing: 0) {
                        IllustrationView(picture: picture)
                            .frame(width: shortSide * pictureRatio, height: shortSide * pictureRatio)
                        if let word = appearance.word {
                            Text(verbatim: word)
                                .font(Typography.cardWord(shortSide: shortSide))
                                .foregroundStyle(Palette.cardInk)
                        }
                    }
                }
            }
    }

    private var pictureRatio: CGFloat {
        appearance.word == nil ? Metrics.cardPictureRatio : Metrics.cardMatchedPictureRatio
    }
}

/// カードの 4 つの状態を並べた見本の画面。撮影モードで開き、引き継ぎブックの 6 ページと見比べるために使う
struct CardCatalogView: View {
    /// 見本のカード 1 枚の状態
    private struct SampleCard {
        let face: Card.Face
        let isFaceUp: Bool
        let isMatched: Bool
    }

    /// 見本のカードの縦横比（プレイ画面では画面の高さで決まる。見本では 3:4）
    private let aspectRatio: CGFloat = 3.0 / 4.0
    /// 動きの見本: 表を見せているか・揃ったか
    @State private var demoFaceUp = false
    @State private var demoMatched = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.screenHorizontalPadding) {
            demoRow
            row("どうぶつ", cards: [
                SampleCard(face: .picture(.cat, word: nil), isFaceUp: false, isMatched: false),
                SampleCard(face: .picture(.cat, word: nil), isFaceUp: true, isMatched: false),
                SampleCard(face: .picture(.cat, word: nil), isFaceUp: true, isMatched: true)
            ])
            row("ひらがな", cards: [
                SampleCard(face: .letter("ね"), isFaceUp: false, isMatched: false),
                SampleCard(face: .letter("ね"), isFaceUp: true, isMatched: false),
                SampleCard(face: .picture(.cat, word: "ねこ"), isFaceUp: true, isMatched: false),
                SampleCard(face: .picture(.cat, word: "ねこ"), isFaceUp: true, isMatched: true)
            ])
            row("ひらがな（そろった）", cards: [
                SampleCard(face: .letter("ね"), isFaceUp: true, isMatched: true),
                SampleCard(face: .letter("ほ"), isFaceUp: true, isMatched: true),
                SampleCard(face: .picture(.star, word: "ほし"), isFaceUp: true, isMatched: true)
            ])
        }
        .padding(.horizontal, Metrics.gameHorizontalPadding)
        .frame(maxHeight: .infinity)
        .background(Palette.background)
    }

    /// めくり・揃ったときの動きの見本。裏 → 表 → そろった → 裏 をくり返す（見本の画面だけで動かす）
    private var demoRow: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text("うごき")
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
            HStack(spacing: Metrics.cardSpacing) {
                CardView(face: .letter("ね"), isFaceUp: demoFaceUp, isMatched: demoMatched)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                CardView(face: .picture(.cat, word: "ねこ"), isFaceUp: demoFaceUp, isMatched: demoMatched)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                ForEach(2..<Metrics.cardColumns, id: \.self) { _ in
                    Color.clear.aspectRatio(aspectRatio, contentMode: .fit)
                }
            }
        }
        .task {
            // 見本の画面だけの動き。ゲームの秒数はゲームのモデルが決める
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Motion.revealAllSixPairs / 2))
                if !demoFaceUp {
                    demoFaceUp = true
                } else if !demoMatched {
                    demoMatched = true
                } else {
                    demoMatched = false
                    demoFaceUp = false
                }
            }
        }
    }

    private func row(_ title: LocalizedStringKey, cards: [SampleCard]) -> some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            Text(title)
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
            HStack(spacing: Metrics.cardSpacing) {
                ForEach(cards.indices, id: \.self) { index in
                    CardView(face: cards[index].face, isFaceUp: cards[index].isFaceUp, isMatched: cards[index].isMatched)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                }
                ForEach(cards.count..<Metrics.cardColumns, id: \.self) { _ in
                    Color.clear.aspectRatio(aspectRatio, contentMode: .fit)
                }
            }
        }
    }
}

#Preview {
    CardCatalogView()
}
