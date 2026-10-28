//
//  AppFlowPurchaseGuardTests.swift
//  ShinkeisuijakuTests
//
//  購入の流れのうち、何もしないとき・途中で変わったときを確かめる（`AppFlowPurchaseTests` の続き。type_body_length のためファイルを分ける）。
//  購入がうまくいかなかったとき・案内や確認を出していないときに届いた操作・購入の途中で画面が変わったとき。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

extension AppFlowPurchaseTests {
    // MARK: - 購入がうまくいかなかったとき

    /// 鍵から来て、購入をやめた・失敗した・検証できなかったときは、ゲームを始めずおうちの方への画面に残る
    /// （押した難易度は覚えたままなので、もう一度買えばそのゲームを始める）
    @Test(arguments: [PassPurchaseResult.cancelled, .failed, .unverified])
    func unsuccessfulPurchaseFromLockedStaysOnParents(result: PassPurchaseResult) async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        let choice = GameChoice(course: .hiragana, difficulty: .normal)
        fixture.backend.nextPurchaseResult = result
        try openGateFromCourse(flow, course: choice.course, difficulty: choice.difficulty)
        flow.parentalGatePassed()
        await fixture.purchase()
        #expect(!flow.hasPass)
        #expect(flow.path == [.parents])
        #expect(flow.session == nil)
        #expect(flow.parentsEntry == .lockedDifficulty(choice))
    }

    // MARK: - 出していないときに届いた操作

    /// クリアの案内を出していない（鍵の付いた次の難易度を押していない）ときの「おうちの方へ」は何もしない
    @Test
    func clearLockedGuideParentsNeedsGuide() throws {
        let flow = makeFixture(data: .initial).flow
        let session = try #require(flow.session)
        flow.recordClear()
        flow.handle(.lockedGuideParents)
        #expect(!flow.isShowingParentalGate)
        #expect(flow.parentsEntry == nil)
        #expect(flow.path == [.game])
        #expect(flow.session === session)
    }

    /// 保護者の確認を出していないとき（出す前・やめた後）に「通った」が届いても、おうちの方への画面を開かない
    @Test
    func gatePassedNeedsGate() throws {
        let flow = makeFixture().flow
        flow.parentalGatePassed()
        #expect(flow.path.isEmpty)
        try openGateFromCourse(flow, course: .animals, difficulty: .hard)
        flow.cancelParentalGate()
        flow.parentalGatePassed()
        #expect(flow.path.isEmpty)
        #expect(!flow.isShowingParentalGate)
    }

    // MARK: - 途中で変わったとき

    /// 購入の途中で画面が変わった（おうちの方への画面を離れた）ら、購入が終わってもゲームを始めない
    @Test
    func purchaseAfterLeavingParentsStartsNothing() async throws {
        let fixture = makeFixture()
        let flow = fixture.flow
        try openGateFromCourse(flow, course: .animals, difficulty: .normal)
        flow.parentalGatePassed()
        fixture.backend.holdsPurchase = true
        let model = fixture.parentsModel()
        model.request(.purchase)
        let running = Task { await model.runPendingAction() }
        try #require(await waitUntil { flow.passStore.isBusy })
        flow.path = []
        fixture.backend.releasePurchase()
        await running.value
        #expect(model.message == .purchased)
        #expect(flow.hasPass)
        #expect(flow.path.isEmpty)
        #expect(flow.session == nil)
    }
}
