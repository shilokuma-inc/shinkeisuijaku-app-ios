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
    /// 前回のコースと難易度（保存と同じ値。ホームの「あそぶ」の表示が変化を見られるよう、観測できる値として持つ）
    private(set) var lastChoice: GameChoice
    /// ホームの上に出しているコース選択のダイアログ（出していないときは nil）
    private(set) var courseSelection: CourseSelection?

    @ObservationIgnored let store: any AppDataStore
    @ObservationIgnored let passStore: PassStore
    @ObservationIgnored let haptics: any Haptics
    @ObservationIgnored private let timing: GameTiming
    @ObservationIgnored private let clock: any GameClock
    @ObservationIgnored private var generator: any RandomNumberGenerator
    /// 遊んでいるゲームのクリアの記録。ゲームごとに作り直し、1 回のゲームで 1 回だけ記録する
    @ObservationIgnored private var recorder: ClearRecorder?

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
        let data = store.load()
        lastChoice = GameChoice(course: data.lastCourse, difficulty: data.lastDifficulty)
        if let choice = LaunchRules.launchGame(data) {
            startGame(choice)
        }
    }

    /// パスの権利があるか（StoreKit の権利。確かめるまでは端末内のキャッシュ）
    var hasPass: Bool {
        passStore.hasPass
    }

    /// ホームの「あそぶ」で始めるゲーム（前回のコースと難易度）
    var resumeChoice: GameChoice {
        LaunchRules.resumeGame(last: lastChoice, hasPass: hasPass)
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
        lastChoice = choice
        recorder = ClearRecorder(course: choice.course, difficulty: choice.difficulty)
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

    /// 遊んでいるゲームのクリアを記録する（スタンプを決めて保存し、振動を鳴らす）。同じゲームで二度呼んでも 1 回だけ記録する
    @discardableResult
    func recordClear() -> ClearOutcome? {
        guard let recorder else {
            return nil
        }
        let outcome = recorder.record(store: store, hasPass: hasPass, haptics: haptics, using: &generator)
        lastChoice = GameChoice(course: outcome.data.lastCourse, difficulty: outcome.data.lastDifficulty)
        return outcome
    }

    /// ホームに戻る（「やめる」・クリアの「ホームにもどる」。初回クリア前に起動してすぐのゲームでも、ホームへ）
    func goHome() {
        path = []
    }

    /// 「ほかの あそびかた」のコースを押したとき。そのコースのコース選択のダイアログを出す
    func chooseCourse(_ course: Course) {
        courseSelection = CourseSelection(course: course)
    }

    /// コース選択のダイアログを閉じる（「とじる」）
    func closeCourseSelection() {
        courseSelection = nil
    }

    /// コース選択のダイアログで難易度を押したとき。鍵が無ければダイアログを閉じてゲームを始め、
    /// 鍵が付いていればゲームは始めずにダイアログの中に案内を出す（購入は保護者の確認のあとだけ）。ダイアログを出していなければ何もしない
    @discardableResult
    func selectDifficulty(_ difficulty: Difficulty) -> CourseSelectResult? {
        guard var selection = courseSelection else {
            return nil
        }
        let result = selection.select(difficulty, hasPass: hasPass)
        switch result {
        case let .start(choice):
            courseSelection = nil
            startGame(choice)
        case .showLockedGuide:
            courseSelection = selection
        }
        return result
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
            // 鍵の付いた難易度はダイアログで案内を出して止めているが、ここでも始めない（購入は保護者の確認のあとだけ）
            guard !difficulty.requiresPass || hasPass else {
                return
            }
            startGame(GameChoice(course: session.course, difficulty: difficulty))
        case .home:
            goHome()
        case .stampBook, .parents:
            // スタンプちょう（タスク 15）・おうちの方へ（タスク 18・19）の画面ができたらつなぐ
            break
        }
    }
}
