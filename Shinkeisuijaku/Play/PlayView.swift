//
//  PlayView.swift
//  Shinkeisuijaku
//
//  プレイ画面（引き継ぎブックの 10 ページ）。上にコース名と「あと◯ペア」と説明の 1 行、中央に 4 列のカード、下にヒントとやめる。
//  タイマー・めくった回数・ミスは出さない。ゲームの進み方は `GameSession` が持ち、この画面は押したことを伝えて見た目を変えるだけ。
//

import SwiftUI

/// プレイ画面
struct PlayView: View {
    /// 遊んでいるゲーム。呼び出し側が作り、ゲームごとに作り直す
    let session: GameSession
    var haptics: any Haptics = SystemHaptics()
    /// やめるを確かめたあと（ホームへ戻る）
    var onQuit: () -> Void = {}
    /// クリアになったとき（クリアのダイアログはタスク 12 で出す）
    var onCleared: () -> Void = {}

    @State private var isConfirmingQuit = false

    /// ゲームが変わる・画面を離れるのを待つ間隔（cancel されたらすぐ戻るので、長くてよい）
    private static let lifetimeCheckInterval: TimeInterval = 3600

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            header
            CardGrid(session: session, haptics: haptics)
                // ゲームが変わったらカードを作り直す（カードの番号は新しいゲームでも 0 から始まるため、
                // 作り直さないと前のゲームの表が一瞬見えることがある）
                .id(ObjectIdentifier(session))
            footer
        }
        .padding(.horizontal, Metrics.gameHorizontalPadding)
        // iPad では中身の幅に上限を設けて中央に置く（カードが横に広がりすぎない）
        .contentWidthLimited()
        .padding(.vertical, Metrics.cardSpacing)
        .background(Palette.background)
        // ゲームごとに始め、ゲームが変わる・画面を離れるまで待ってから、そのゲームの待っている処理
        // （全部見せる・ハズレを戻す・クリアまでの間）を止める
        .task(id: ObjectIdentifier(session)) {
            let current = session
            current.start()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.lifetimeCheckInterval))
            }
            current.quit()
        }
        .onChange(of: session.phase) { _, phase in
            if phase == .cleared {
                // 確かめているあいだにクリアになったら、確かめるのをやめてクリアに進む（やめるとクリアの両方に進まない）
                isConfirmingQuit = false
                onCleared()
            }
        }
        .alert("やめますか？", isPresented: $isConfirmingQuit) {
            Button("やめる") {
                guard session.phase != .cleared else {
                    return
                }
                session.quit()
                onQuit()
            }
            Button("つづける", role: .cancel) {}
        }
    }

    /// コース名と「あと◯ペア」、説明の 1 行
    private var header: some View {
        VStack(spacing: Metrics.pairCountVerticalPadding) {
            HStack(alignment: .firstTextBaseline, spacing: Metrics.cardSpacing) {
                Text(session.course.name)
                    .lineLimit(1)
                    .appFont(Typography.note)
                    .foregroundStyle(Palette.muted)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("あと ")
                        .appFont(Typography.pairCountLabel)
                    Text(session.remainingPairs, format: .number)
                        .appFont(Typography.pairCountNumber)
                        .foregroundStyle(Palette.accent)
                    Text(" ペア")
                        .appFont(Typography.pairCountLabel)
                }
                .foregroundStyle(Palette.text)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.vertical, Metrics.pairCountVerticalPadding)
            .padding(.horizontal, Metrics.pairCountHorizontalPadding)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.pairCountCornerRadius)
                    .stroke(Palette.border, lineWidth: Metrics.borderWidth)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("play.remainingPairs")
            Text(Self.explanation(for: session.course))
                .appFont(Typography.body)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    /// ヒントとやめる
    private var footer: some View {
        HStack(spacing: Metrics.cardSpacing) {
            Button {
                session.showHint()
            } label: {
                HStack(spacing: Metrics.cardSpacing) {
                    HintEyesView()
                        .frame(height: Metrics.hintIconHeight)
                    Text("ヒント")
                        .appFont(Typography.button)
                }
                .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            }
            .buttonStyle(SurfaceButtonStyle())
            .disabled(!session.canShowHint)
            .accessibilityIdentifier("play.hint")
            Button {
                isConfirmingQuit = true
            } label: {
                Text("やめる")
                    .appFont(Typography.button)
                    .frame(maxWidth: .infinity, minHeight: Metrics.buttonHeight)
            }
            .buttonStyle(SurfaceButtonStyle())
            // 全部揃った後は、クリアのダイアログを待つのであって、やめるには進めない
            .disabled(session.phase == .finishing || session.phase == .cleared)
            .accessibilityIdentifier("play.quit")
        }
    }

    /// 説明の 1 行（子ども向けなのでひらがな）
    static func explanation(for course: Course) -> LocalizedStringKey {
        switch course {
        case .animals: "おなじ えを 2まい さがしてね"
        case .hiragana: "もじと えの ペアを さがしてね"
        }
    }
}

/// 4 列のカード。行は使える高さで等分する（iPhone SE でもスクロールせずに収まる）。
/// カードが縦に長くなりすぎないよう高さに上限があるので（`CardGridLayout`）、あまった高さは上下に分けて真ん中に置く
private struct CardGrid: View {
    let session: GameSession
    let haptics: any Haptics

    var body: some View {
        GeometryReader { proxy in
            let cards = session.board.cards
            let layout = CardGridLayout(cardCount: cards.count, available: proxy.size)
            VStack(spacing: Metrics.cardSpacing) {
                ForEach(0..<layout.rows, id: \.self) { row in
                    HStack(spacing: Metrics.cardSpacing) {
                        ForEach(cards.indices.filter { $0 / layout.columns == row }, id: \.self) { index in
                            cardButton(cards[index], index: index)
                                .frame(width: layout.cardSize.width, height: layout.cardSize.height)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func cardButton(_ card: Card, index: Int) -> some View {
        Button {
            if session.flip(cardID: card.id) == .matched {
                haptics.matched()
            }
        } label: {
            CardView(face: card.face, isFaceUp: session.isShowingFace(of: card), isMatched: card.isMatched)
        }
        .buttonStyle(.plain)
        // disabled にすると全部見せているあいだにカードが薄くなるので、押せないようにするだけにする
        .allowsHitTesting(!session.isInputLocked && !card.isFaceUp)
        .accessibilityIdentifier(UITestingLaunch.cardIdentifier(index: index, pairID: card.pairID))
    }
}

/// 通常のボタン（面の色の地・境界線 1・角丸 14・高さ 52）。押しているあいだと押せないときは薄くする
struct SurfaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SurfaceButton(configuration: configuration)
    }

    private struct SurfaceButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .foregroundStyle(Palette.text)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius)
                        .stroke(Palette.border, lineWidth: Metrics.borderWidth)
                }
                .opacity(configuration.isPressed || !isEnabled ? Metrics.pressedOpacity : 1)
        }
    }
}

/// 撮影モードのプレイ画面。ひらがな・やさしいで、2 組揃えて 1 枚めくった状態をデモの盤面で開く（保存も振動も使わない）
struct PlayScreenshotDemoView: View {
    @State private var session: GameSession = {
        var generator = SeededRandomNumberGenerator(seed: 4)
        return GameSession(
            course: .hiragana,
            difficulty: .easy,
            isBeforeFirstClear: false,
            timing: .standard,
            clock: InstantGameClock(),
            using: &generator
        )
    }()

    var body: some View {
        PlayView(session: session, haptics: SilentHaptics())
            .task {
                session.start()
                await session.waitForPendingWork()
                let pairs = Dictionary(grouping: session.board.cards, by: \.pairID).values.sorted { $0[0].pairID < $1[0].pairID }
                for pair in pairs.prefix(2) {
                    session.flip(cardID: pair[0].id)
                    session.flip(cardID: pair[1].id)
                }
                if let next = pairs.dropFirst(2).first {
                    session.flip(cardID: next[0].id)
                }
            }
    }
}
