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
        /// スタンプちょう
        case stampBook
        /// おうちの方への画面（保護者の確認を通ったあとにだけ積む）
        case parents
    }

    /// おうちの方への流れを始めたところ
    enum ParentsEntry: Equatable {
        /// ホームの「おうちの方へ」
        case home
        /// 鍵の付いた難易度の案内の下の「おうちの方へ」（コース選択・クリアの次の難易度）。購入が終わったら、このゲームをすぐ始める
        case lockedDifficulty(GameChoice)
        /// クリアの「もっと むずかしいのは おうちの方へ」。押した難易度が無いので、購入してもゲームは始めない
        case clearGuide
    }

    /// ホームの上に積んだ画面（`NavigationStack` の path）
    var path: [Destination] = []
    /// 遊んでいる（最後に始めた）ゲーム。ホームに戻っても、戻る動きのあいだ画面に出ているので残す
    private(set) var session: GameSession?
    /// 前回のコースと難易度（保存と同じ値。ホームの「あそぶ」の表示が変化を見られるよう、観測できる値として持つ）
    private(set) var lastChoice: GameChoice
    /// ホームの上に出しているコース選択のダイアログ（出していないときは nil）
    private(set) var courseSelection: CourseSelection?
    /// 保護者の確認のダイアログを出しているか（「おうちの方へ」を押してから、通るかやめるまで）
    private(set) var isShowingParentalGate = false
    /// おうちの方への流れ（保護者の確認 → おうちの方への画面）をどこから始めたか（流れの外では nil）
    private(set) var parentsEntry: ParentsEntry?
    /// クリアのダイアログで押した、鍵の付いた次の難易度（案内を出している。押していなければ nil。ゲームを始めるたびに消す）
    private(set) var clearLockedDifficulty: Difficulty?

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
        clearLockedDifficulty = nil
        parentsEntry = nil
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
    /// おうちの方への画面の「ホームにもどる」でも呼ぶので、覚えていた押した難易度を捨てる（購入しないで戻ったら、何も始めない）
    func goHome() {
        path = []
        parentsEntry = nil
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

    /// スタンプちょうを開く（ホームのボタン・クリアの「スタンプちょう」）。クリアから開いたときもプレイを残さないので、戻るとホームへ
    func openStampBook() {
        path = [.stampBook]
    }

    /// スタンプちょうの並べ方（保存の持っているスタンプとパスの権利から。開くたびに保存を読み直す）
    var stampBookLayout: StampBookLayout {
        StampBookLayout(owned: StampCollection(ids: store.load().ownedStampIDs), hasPass: hasPass)
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
            // 鍵の付いた難易度は始めずに、押したものを覚えて案内を出す（購入は保護者の確認のあとだけ）
            guard !CourseSelection.isLocked(difficulty, hasPass: hasPass) else {
                clearLockedDifficulty = difficulty
                return
            }
            startGame(GameChoice(course: session.course, difficulty: difficulty))
        case .home:
            goHome()
        case .stampBook:
            openStampBook()
        case .lockedGuideParents:
            guard let locked = clearLockedDifficulty, showsClearLockedGuide else {
                return
            }
            beginParents(from: .lockedDifficulty(GameChoice(course: session.course, difficulty: locked)))
        case .parents:
            beginParents(from: .clearGuide)
        }
    }

    /// クリアのダイアログに「おうちの方に あけてもらってね」を出すか（鍵の付いた次の難易度を押した後。パスを買ったら消す）
    var showsClearLockedGuide: Bool {
        guard let clearLockedDifficulty else {
            return false
        }
        return CourseSelection.isLocked(clearLockedDifficulty, hasPass: hasPass)
    }

    /// ホームの「おうちの方へ」。おうちの方への画面は開かずに、先に保護者の確認のダイアログを出す（購入と外部のリンクは確認のあとだけ）
    func openParents() {
        beginParents(from: .home)
    }

    /// コース選択のダイアログの案内の下の「おうちの方へ」。ダイアログを閉じて保護者の確認を出し、押した難易度を覚えておく。
    /// 案内を出していなければ（鍵の付いた難易度を押していない・もう買った）何もしない
    func openParentsForLockedCourse() {
        guard let selection = courseSelection, let locked = selection.lockedDifficulty, selection.showsLockedGuide(hasPass: hasPass) else {
            return
        }
        beginParents(from: .lockedDifficulty(GameChoice(course: selection.course, difficulty: locked)))
    }

    /// おうちの方への流れを始める。出しているコース選択のダイアログは閉じ（確認をやめたらホームに戻るので、開き直さない）、保護者の確認を出す
    private func beginParents(from entry: ParentsEntry) {
        courseSelection = nil
        parentsEntry = entry
        isShowingParentalGate = true
    }

    /// 保護者の確認を通ったとき。ダイアログを閉じて、おうちの方への画面にする（クリアから来たときもプレイを残さないので、戻るとホームへ）。
    /// ダイアログを出していなければ何もしない。購入の画面には進むが、購入は保護者が「購入する」を押したときだけ
    func parentalGatePassed() {
        guard isShowingParentalGate else {
            return
        }
        isShowingParentalGate = false
        path = [.parents]
    }

    /// 保護者の確認をやめたとき。ダイアログを閉じてホームに戻る（クリアから来たときも。押した難易度は捨てる）。
    /// 購入の案内をくり返し出さないよう、コース選択のダイアログも開き直さない
    func cancelParentalGate() {
        isShowingParentalGate = false
        courseSelection = nil
        goHome()
    }

    /// おうちの方への画面で購入が終わったとき（`.purchased`）。鍵の付いた難易度から来ていれば、そのゲームをすぐ始める。
    /// ホームやクリアの「もっと むずかしいのは」から来たときは、画面に残って購入できた文を出す（押した難易度が無い）。
    /// 復元・承認待ちの承認・前面に戻ったときの確認で権利が付いたときは呼ばない（保護者が結果の文を読めるよう、画面を変えない）
    func purchaseCompleted() {
        guard path == [.parents], hasPass, case let .lockedDifficulty(choice) = parentsEntry else {
            return
        }
        startGame(choice)
    }
}
