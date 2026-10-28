//
//  AppFlowTests.swift
//  ShinkeisuijakuTests
//
//  画面の流れ（起動したときに積む画面・あそぶ・やめる・クリアのあとの行き先）を、メモリ上の保存と擬似のストアで確かめる。
//

import Foundation
import Observation
@testable import Shinkeisuijaku
import Testing

struct AppFlowTests {
    private func makeFlow(data: AppData = .initial, entitled: Bool = false) -> (flow: AppFlow, store: InMemoryAppDataStore) {
        let store = InMemoryAppDataStore(data: data)
        let passStore = PassStore(backend: FakePassStoreBackend(entitled: entitled), dataStore: store)
        let flow = AppFlow(
            store: store,
            passStore: passStore,
            haptics: SilentHaptics(),
            clock: InstantGameClock(),
            generator: SeededRandomNumberGenerator(seed: 7)
        )
        return (flow, store)
    }

    /// 初めて起動したときは、プレイを積んだ状態（どうぶつ・やさしい・初回クリア前）で始まる
    @Test
    func firstLaunchStartsWithGame() throws {
        let flow = makeFlow().flow
        #expect(flow.path == [.game])
        let session = try #require(flow.session)
        #expect(session.course == .animals)
        #expect(session.difficulty == .easy)
        #expect(session.isBeforeFirstClear)
    }

    /// 1 回クリアした後に起動したときは、ホームから始まる（ゲームを用意しない）
    @Test
    func launchAfterFirstClearShowsHome() {
        let flow = makeFlow(data: AppData(hasClearedOnce: true)).flow
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
    }

    /// 初回クリア前に起動してすぐのゲームでも、「やめる」でホームに戻る
    @Test
    func quitFromFirstGameGoesHome() {
        let flow = makeFlow().flow
        flow.goHome()
        #expect(flow.path.isEmpty)
    }

    /// 「あそぶ」は前回のコースと難易度で始める（初回クリア後なので全部見せる時間は短い方）
    @Test
    func playStartsLastChoice() throws {
        // パスの権利は StoreKit で確かめるまで端末内のキャッシュなので、キャッシュも持たせる
        let data = AppData(hasPassCache: true, lastCourse: .hiragana, lastDifficulty: .hard, hasClearedOnce: true)
        let flow = makeFlow(data: data, entitled: true).flow
        flow.play()
        #expect(flow.path == [.game])
        let session = try #require(flow.session)
        #expect(session.course == .hiragana)
        #expect(session.difficulty == .hard)
        #expect(!session.isBeforeFirstClear)
    }

    /// パスの権利が無いとき、前回の難易度に鍵が付いていれば そのコースのやさしいで始め、前回として保存する
    @Test
    func playFallsBackToEasyWhenLocked() throws {
        let data = AppData(lastCourse: .hiragana, lastDifficulty: .normal, hasClearedOnce: true)
        let (flow, store) = makeFlow(data: data)
        #expect(flow.resumeChoice == GameChoice(course: .hiragana, difficulty: .easy))
        flow.play()
        let session = try #require(flow.session)
        #expect(session.difficulty == .easy)
        #expect(store.data.lastCourse == .hiragana)
        #expect(store.data.lastDifficulty == .easy)
    }

    /// ゲームを始めると、コースと難易度を前回のものとして保存する（ほかの項目は変えない）
    @Test
    func startGameSavesLastChoice() {
        let data = AppData(ownedStampIDs: ["cat"], hasPassCache: true, hasClearedOnce: true)
        let (flow, store) = makeFlow(data: data, entitled: true)
        flow.startGame(GameChoice(course: .hiragana, difficulty: .normal))
        #expect(store.data.lastCourse == .hiragana)
        #expect(store.data.lastDifficulty == .normal)
        #expect(store.data.ownedStampIDs == ["cat"])
        #expect(store.data.hasPassCache)
        #expect(store.data.hasClearedOnce)
    }

    /// 「もう一回あそぶ」は同じコースと難易度の新しいゲームにする
    @Test
    func playAgainStartsNewGame() throws {
        let flow = makeFlow().flow
        let first = try #require(flow.session)
        flow.handle(.playAgain)
        let second = try #require(flow.session)
        #expect(first !== second)
        #expect(second.course == first.course)
        #expect(second.difficulty == first.difficulty)
        #expect(flow.path == [.game])
    }

    /// 次の難易度は、同じコースの次の難易度の新しいゲームにする
    @Test
    func nextDifficultyStartsThatGame() throws {
        let data = AppData(hasPassCache: true, lastCourse: .hiragana, hasClearedOnce: true)
        let flow = makeFlow(data: data, entitled: true).flow
        flow.play()
        flow.handle(.nextDifficulty(.normal))
        let session = try #require(flow.session)
        #expect(session.course == .hiragana)
        #expect(session.difficulty == .normal)
        #expect(flow.path == [.game])
    }

    /// 鍵の付いた次の難易度（パスの権利が無い）は、押されても始めない
    @Test
    func lockedNextDifficultyDoesNotStart() throws {
        let flow = makeFlow().flow
        let first = try #require(flow.session)
        flow.handle(.nextDifficulty(.normal))
        #expect(flow.session === first)
        #expect(first.difficulty == .easy)
    }

    /// クリアは 1 回のゲームで 1 回だけ記録し、「もう一回あそぶ」の後のクリアはまた記録する（スタンプが増える）
    @Test
    func recordClearOncePerGame() throws {
        let (flow, store) = makeFlow()
        let first = try #require(flow.recordClear())
        #expect(flow.recordClear() == first)
        #expect(store.data.ownedStampIDs.count == 1)
        #expect(store.data.hasClearedOnce)
        flow.handle(.playAgain)
        let second = try #require(flow.session)
        #expect(!second.isBeforeFirstClear, "1 回クリアした後のゲームは、全部見せる時間が短い方")
        flow.recordClear()
        #expect(store.data.ownedStampIDs.count == 2)
    }

    /// ゲームを始めると、ホームの「あそぶ」の表示（前回のコースと難易度）が変わったと画面に伝わる
    @Test
    func resumeChoiceIsObservable() async {
        let flow = makeFlow(data: AppData(hasClearedOnce: true)).flow
        #expect(flow.resumeChoice == GameChoice(course: .animals, difficulty: .easy))
        await confirmation { changed in
            withObservationTracking {
                _ = flow.resumeChoice
            } onChange: {
                changed()
            }
            flow.startGame(GameChoice(course: .hiragana, difficulty: .easy))
        }
        #expect(flow.resumeChoice == GameChoice(course: .hiragana, difficulty: .easy))
    }

    /// クリアの「ホームにもどる」でホームに戻る
    @Test
    func homeActionGoesHome() {
        let flow = makeFlow().flow
        flow.handle(.home)
        #expect(flow.path.isEmpty)
    }

    /// 「ほかの あそびかた」のコースを押すと、そのコースのコース選択のダイアログが出る（ゲームはまだ始めない）
    @Test(arguments: Course.allCases)
    func chooseCourseShowsDialog(course: Course) {
        let flow = makeFlow(data: AppData(hasClearedOnce: true)).flow
        #expect(flow.courseSelection == nil)
        flow.chooseCourse(course)
        #expect(flow.courseSelection == CourseSelection(course: course))
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
    }

    /// 鍵の無い難易度を押すと、ダイアログを閉じて そのコースと難易度のゲームを始める
    @Test
    func unlockedDifficultyStartsGameAndClosesDialog() throws {
        let (flow, store) = makeFlow(data: AppData(hasClearedOnce: true))
        flow.chooseCourse(.hiragana)
        let result = flow.selectDifficulty(.easy)
        #expect(result == .start(GameChoice(course: .hiragana, difficulty: .easy)))
        #expect(flow.courseSelection == nil)
        #expect(flow.path == [.game])
        let session = try #require(flow.session)
        #expect(session.course == .hiragana)
        #expect(session.difficulty == .easy)
        #expect(store.data.lastCourse == .hiragana)
    }

    /// 鍵の付いた難易度を押しても、ゲームは始まらず、ダイアログを出したまま案内を出す
    @Test
    func lockedDifficultyShowsGuideWithoutStarting() {
        let (flow, store) = makeFlow(data: AppData(hasClearedOnce: true))
        flow.chooseCourse(.animals)
        let result = flow.selectDifficulty(.hard)
        #expect(result == .showLockedGuide)
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
        let selection = flow.courseSelection
        #expect(selection?.course == .animals)
        #expect(selection?.lockedDifficulty == .hard)
        #expect(selection?.showsLockedGuide(hasPass: flow.hasPass) == true)
        #expect(store.data.lastDifficulty == .easy, "始めていないので前回の難易度は変えない")
    }

    /// パスの権利があれば、ふつう・むずかしいも押すとゲームを始める
    @Test
    func passStartsLockedDifficulty() throws {
        let data = AppData(hasPassCache: true, hasClearedOnce: true)
        let flow = makeFlow(data: data, entitled: true).flow
        flow.chooseCourse(.hiragana)
        #expect(flow.selectDifficulty(.normal) == .start(GameChoice(course: .hiragana, difficulty: .normal)))
        #expect(flow.courseSelection == nil)
        let session = try #require(flow.session)
        #expect(session.difficulty == .normal)
    }

    /// 「とじる」でダイアログを閉じる（ゲームは始めない）。ダイアログを出していなければ難易度を押しても何もしない
    @Test
    func closeCourseSelectionHidesDialog() {
        let flow = makeFlow(data: AppData(hasClearedOnce: true)).flow
        flow.chooseCourse(.animals)
        flow.closeCourseSelection()
        #expect(flow.courseSelection == nil)
        #expect(flow.selectDifficulty(.easy) == nil)
        #expect(flow.session == nil)
        #expect(flow.path.isEmpty)
    }

    // MARK: - スタンプちょう

    /// ホームのスタンプちょうのボタンで、スタンプちょうを積み、「ホームにもどる」でホームに戻る
    @Test
    func openStampBookFromHome() {
        let flow = makeFlow(data: AppData(hasClearedOnce: true)).flow
        flow.openStampBook()
        #expect(flow.path == [.stampBook])
        flow.goHome()
        #expect(flow.path.isEmpty)
    }

    /// クリアの「スタンプちょう」は、プレイを残さずにスタンプちょうにする（戻るとホームへ）
    @Test
    func clearStampBookActionReplacesGame() {
        let flow = makeFlow().flow
        #expect(flow.path == [.game])
        flow.recordClear()
        flow.handle(.stampBook)
        #expect(flow.path == [.stampBook])
        flow.goHome()
        #expect(flow.path.isEmpty)
    }

    /// スタンプちょうは保存のスタンプを出し、クリアでもらったスタンプも数に入る
    @Test
    func stampBookShowsSavedStamps() throws {
        let data = AppData(ownedStampIDs: [Stamp.regular(.dog).id])
        let flow = makeFlow(data: data).flow
        #expect(flow.stampBookLayout.collectedCount == 1)
        let outcome = try #require(flow.recordClear())
        let awarded = try #require(outcome.awardedStamp)
        flow.handle(.stampBook)
        let layout = flow.stampBookLayout
        #expect(layout.collectedCount == 2)
        #expect(layout.regular.contains { $0.slot == .owned(awarded) })
    }

    /// パスの権利が無ければパス専用の枠は鍵、あれば鍵を消す
    @Test
    func stampBookLockFollowsPass() {
        let locked = makeFlow(data: AppData(hasClearedOnce: true)).flow
        #expect(locked.stampBookLayout.pass.allSatisfy { $0.slot == .locked })
        // パスの権利は StoreKit で確かめるまで端末内のキャッシュなので、キャッシュも持たせる
        let unlocked = makeFlow(data: AppData(hasPassCache: true, hasClearedOnce: true), entitled: true).flow
        #expect(unlocked.stampBookLayout.pass.allSatisfy { $0.slot == .empty })
    }
}
