//
//  AppFlow.swift
//  Shinkeisuijaku
//
//  画面の流れ（ホーム → プレイ、クリアのあとの行き先）と、遊んでいるゲームを持つ。
//  初回クリア前はプレイを積んだ状態で始めるので、ホームを通らずにゲームが始まり、「やめる」でホームに戻る。
//

import Foundation
import Observation

/// アプリの画面の流れ
@Observable
final class AppFlow {
    /// ホームの上に積む画面
    enum Destination: Hashable {
        /// プレイ（クリアのダイアログを含む）
        case game
    }

    /// ホームの上に積んだ画面（`NavigationStack` の path）
    var path: [Destination] = []
    /// 遊んでいる（最後に始めた）ゲーム。ホームに戻っても、戻る動きのあいだ画面に出ているので残す
    private(set) var session: GameSession?

    @ObservationIgnored let store: any AppDataStore
    @ObservationIgnored let passStore: PassStore
    @ObservationIgnored let haptics: any Haptics
    @ObservationIgnored private let timing: GameTiming
    @ObservationIgnored private let clock: any GameClock
    @ObservationIgnored private var generator: any RandomNumberGenerator

    /// 保存の中身を見て、初回クリア前ならゲームを始めた状態で用意する
    /// - Parameter generator: カードを配る乱数。テストでは種を固定したものを渡す
    init(
        store: any AppDataStore,
        passStore: PassStore,
        haptics: any Haptics,
        timing: GameTiming = .standard,
        clock: any GameClock = SystemGameClock(),
        generator: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.store = store
        self.passStore = passStore
        self.haptics = haptics
        self.timing = timing
        self.clock = clock
        self.generator = generator
        if let choice = LaunchRules.launchGame(store.load()) {
            startGame(choice)
        }
    }

    /// パスの権利があるか（StoreKit の権利。確かめるまでは端末内のキャッシュ）
    var hasPass: Bool {
        passStore.hasPass
    }

    /// ホームの「あそぶ」で始めるゲーム（前回のコースと難易度）
    var resumeChoice: GameChoice {
        LaunchRules.resumeGame(store.load(), hasPass: hasPass)
    }

    /// ホームの「あそぶ」。前回のコースと難易度で始める
    func play() {
        startGame(resumeChoice)
    }

    /// ゲームを始めてプレイの画面に進む。コースと難易度は前回のものとして保存する（次の「あそぶ」で始める）
    func startGame(_ choice: GameChoice) {
        var data = store.load()
        if data.lastCourse != choice.course || data.lastDifficulty != choice.difficulty {
            data.lastCourse = choice.course
            data.lastDifficulty = choice.difficulty
            store.save(data)
        }
        session = GameSession(
            course: choice.course,
            difficulty: choice.difficulty,
            isBeforeFirstClear: !data.hasClearedOnce,
            timing: timing,
            clock: clock,
            using: &generator
        )
        if path != [.game] {
            path = [.game]
        }
    }

    /// ホームに戻る（「やめる」・クリアの「ホームにもどる」。初回クリア前に起動してすぐのゲームでも、ホームへ）
    func goHome() {
        path = []
    }

    /// クリアのダイアログで押したもの
    func handle(_ action: ClearAction) {
        guard let session else {
            return
        }
        switch action {
        case .playAgain:
            startGame(GameChoice(course: session.course, difficulty: session.difficulty))
        case let .nextDifficulty(difficulty):
            startGame(GameChoice(course: session.course, difficulty: difficulty))
        case .home:
            goHome()
        case .stampBook, .parents:
            // スタンプちょう（タスク 15）・おうちの方へ（タスク 18・19）の画面ができたらつなぐ
            break
        }
    }
}
