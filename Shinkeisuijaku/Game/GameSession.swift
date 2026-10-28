//
//  GameSession.swift
//  Shinkeisuijaku
//
//  1 回のゲームの進み方（最初に全部見せる・めくり・ハズレを裏返す・ヒント・クリア）。
//  時間の経過は `GameClock` を注入し、テストでは実際の時間を待たない。秒数は `GameTiming` で外から渡す。
//

import Foundation
import Observation

/// 時間を待つもの。アプリでは `Task.sleep`、テストでは差し替える（ゲームの進みは画面と同じ MainActor で扱う）
@MainActor
protocol GameClock {
    /// 指定した秒数だけ待つ。Task が cancel されたら早めに戻ってよい
    func sleep(for seconds: TimeInterval) async
}

/// `Task.sleep` で実際の時間を待つ時計
struct SystemGameClock: GameClock {
    func sleep(for seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}

/// ゲームの秒数。値はデザイントークン（引き継ぎブックの「動き」）から作り、UI テストでは短くする
struct GameTiming: Sendable {
    /// 始めに全部見せる時間（ペアの数・初回クリア前か から決める）
    let revealAll: @MainActor @Sendable (_ pairCount: Int, _ isBeforeFirstClear: Bool) -> TimeInterval
    /// ハズレの 2 枚が裏に戻るまでの時間
    let mismatchDelay: TimeInterval
    /// ヒントで全部見せる時間
    let hintDuration: TimeInterval
    /// 全部揃ってから、クリアのダイアログを出すまでの間
    let clearDialogDelay: TimeInterval

    /// 引き継ぎブックの「動き」の秒数（デザイントークンの `Motion`）
    static let standard = GameTiming(
        revealAll: { pairCount, isBeforeFirstClear in
            Motion.revealAllDuration(pairCount: pairCount, isBeforeFirstClear: isBeforeFirstClear)
        },
        mismatchDelay: Motion.mismatchDelay,
        hintDuration: Motion.hintDuration,
        clearDialogDelay: Motion.clearDialogDelay
    )
}

/// 1 回のゲーム。待つ処理（全部見せる・ハズレを戻す・ヒント・クリアまでの間）はセッションが自分の Task で進め、
/// `quit()` でまとめて止める。画面はボタンを押したときに同期のメソッドを呼び、`phase` と `board` の変化を見る
@Observable
final class GameSession {
    /// ゲームの段階
    enum Phase: Equatable, Sendable {
        /// 始まる前
        case ready
        /// 始めに全部のカードを見せている
        case revealingAll
        /// カードをめくれる
        case playing
        /// ハズレの 2 枚を見せていて、裏に戻すのを待っている
        case resolvingMismatch
        /// ヒントで全部のカードを見せている
        case hinting
        /// 全部揃って、クリアのダイアログを出すのを待っている
        case finishing
        /// クリア（ダイアログを出す）
        case cleared
        /// 「やめる」で止めた。これより先には進まない（クリアにもならない）
        case quit
    }

    let course: Course
    let difficulty: Difficulty
    /// 初回クリア前のゲームか（始めに全部見せる時間が長くなる）
    let isBeforeFirstClear: Bool
    private(set) var board: GameBoard
    private(set) var phase: Phase = .ready

    @ObservationIgnored private let timing: GameTiming
    @ObservationIgnored private let clock: any GameClock
    /// 待っている処理。同時に 1 つだけ（待っているあいだは `phase` が `.playing` でないので、次の操作は入らない）
    @ObservationIgnored private var pendingTask: Task<Void, Never>?

    /// コースと難易度のカードを配って、ゲームを用意する
    /// - Parameter generator: カードを配る乱数。テストと UI テストでは種を固定したものを渡す
    init(
        course: Course,
        difficulty: Difficulty,
        isBeforeFirstClear: Bool,
        timing: GameTiming,
        clock: any GameClock = SystemGameClock(),
        using generator: inout some RandomNumberGenerator
    ) {
        self.course = course
        self.difficulty = difficulty
        self.isBeforeFirstClear = isBeforeFirstClear
        board = GameDealer.deal(course: course, difficulty: difficulty, using: &generator)
        self.timing = timing
        self.clock = clock
    }

    /// 揃っていないペアの数（「あと◯ペア」）
    var remainingPairs: Int {
        board.remainingPairs
    }

    /// カードを押せないか（全部見せている・ハズレを戻すのを待っている・ヒント・クリアの後）
    var isInputLocked: Bool {
        phase != .playing
    }

    /// ヒントを押せるか
    var canShowHint: Bool {
        phase == .playing
    }

    /// カードの表を見せるか（めくった・揃った、または全部見せている・ヒントのあいだ）
    func isShowingFace(of card: Card) -> Bool {
        card.isFaceUp || phase == .revealingAll || phase == .hinting
    }

    /// 始めに全部のカードを見せ、時間がたったらめくれるようにする
    func start() {
        guard phase == .ready else {
            return
        }
        phase = .revealingAll
        wait(for: timing.revealAll(difficulty.pairCount, isBeforeFirstClear)) { session in
            session.phase = .playing
        }
    }

    /// カードを 1 枚めくる。結果はすぐに返し（揃ったときの振動に使う）、ハズレを戻す・クリアにするのは後で進める
    /// - Returns: めくった結果
    @discardableResult
    func flip(cardID: Card.ID) -> FlipResult {
        guard phase == .playing else {
            return .ignored
        }
        let result = board.flip(cardID: cardID)
        switch result {
        case .ignored, .firstCard:
            break
        case .matched:
            if board.isCleared {
                phase = .finishing
                wait(for: timing.clearDialogDelay) { session in
                    session.phase = .cleared
                }
            }
        case .mismatched:
            phase = .resolvingMismatch
            wait(for: timing.mismatchDelay) { session in
                session.board.concealMismatch()
                session.phase = .playing
            }
        }
        return result
    }

    /// ヒント: 裏のカードを全部、少しのあいだだけ見せる（回数の制限はなし）
    func showHint() {
        guard canShowHint else {
            return
        }
        phase = .hinting
        wait(for: timing.hintDuration) { session in
            session.phase = .playing
        }
    }

    /// 「やめる」: 待っている処理を止め、これより先に進めない（揃えた直後にやめても、クリアにしない）
    func quit() {
        pendingTask?.cancel()
        pendingTask = nil
        phase = .quit
    }

    /// 待っている処理が終わるまで待つ（テストで、時計を進めた後の状態を確かめるため）
    func waitForPendingWork() async {
        await pendingTask?.value
    }

    /// 少し待ってから次の段階に進める。`quit()` で止めたら進めない
    private func wait(for seconds: TimeInterval, then advance: @escaping (GameSession) -> Void) {
        let clock = clock
        pendingTask = Task { [weak self] in
            await clock.sleep(for: seconds)
            guard !Task.isCancelled, let self, self.phase != .quit else {
                return
            }
            self.pendingTask = nil
            advance(self)
        }
    }
}
