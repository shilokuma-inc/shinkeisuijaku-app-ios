//
//  StampRulesTests.swift
//  ShinkeisuijakuTests
//
//  スタンプの種類と、クリアしたときのもらい方（Discussion #4 の Q7）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct StampRulesTests {
    private func award(
        _ course: Course,
        _ difficulty: Difficulty,
        hasPass: Bool,
        owned: [Stamp] = [],
        seed: UInt64 = 1
    ) -> Stamp? {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return StampRules.award(
            course: course,
            difficulty: difficulty,
            hasPass: hasPass,
            owned: StampCollection(ids: owned.map(\.id)),
            using: &generator
        )
    }

    // MARK: - 種類

    /// 通常は仕様書の 12 種類（ホシは入らない）、パス専用はコース × 銀・金の 4 つ
    @Test
    func thereAreTwelveRegularAndFourPassStamps() {
        #expect(Stamp.regularStamps.count == 12)
        #expect(!Stamp.regularPictures.contains(.star))
        #expect(Set(Stamp.regularStamps).count == 12)
        #expect(Stamp.passStamps == [.pass(.animals, .silver), .pass(.animals, .gold), .pass(.hiragana, .silver), .pass(.hiragana, .gold)])
    }

    /// 保存の識別子は一度出したら変えない（変わると保存済みのスタンプが読めずに消える）。
    /// 識別子は絵やコースの rawValue から作るので、そちらの名前を変えたときに気づけるよう、全部を文字列で固定する
    @Test
    func storedIDsNeverChange() {
        let ids = (Stamp.regularStamps + Stamp.passStamps).map(\.id)
        #expect(ids == [
            "regular.cat", "regular.dog", "regular.rabbit", "regular.panda", "regular.frog", "regular.chick",
            "regular.fox", "regular.penguin", "regular.apple", "regular.strawberry", "regular.bear", "regular.suika",
            "pass.animals.silver", "pass.animals.gold", "pass.hiragana.silver", "pass.hiragana.gold"
        ])
    }

    /// 保存の識別子から同じスタンプに戻る。識別子は重ならない
    @Test
    func idsRoundTripAndAreUnique() {
        let all = Stamp.regularStamps + Stamp.passStamps
        #expect(all.allSatisfy { Stamp(id: $0.id) == $0 })
        #expect(Set(all.map(\.id)).count == 16)
        #expect(Stamp.regular(.cat).id == "regular.cat")
        #expect(Stamp.pass(.hiragana, .gold).id == "pass.hiragana.gold")
        #expect(Stamp(id: "regular.star") == nil)
        #expect(Stamp(id: "pass.kazu.gold") == nil)
    }

    /// 保存の識別子から持っているスタンプを作るとき、知らない識別子と重なりは除く
    @Test
    func collectionIgnoresUnknownAndDuplicateIDs() {
        let collection = StampCollection(ids: ["regular.dog", "regular.dog", "regular.unknown", "pass.animals.silver"])
        #expect(collection.stamps == [.regular(.dog), .pass(.animals, .silver)])
        #expect(collection.regularCount == 1)
        #expect(collection.missingRegularStamps.count == 11)
    }

    // MARK: - もらい方

    /// やさしいをクリアすると、まだ持っていない通常のスタンプを 1 つもらう（パスがあってもなくても）
    @Test
    func easyGivesAMissingRegularStamp() {
        for hasPass in [false, true] {
            let owned = Array(Stamp.regularStamps.prefix(5))
            let stamp = award(.animals, .easy, hasPass: hasPass, owned: owned)
            #expect(stamp != nil)
            if let stamp {
                #expect(Stamp.regularStamps.contains(stamp))
                #expect(!owned.contains(stamp))
            }
        }
    }

    /// 通常のスタンプが残り 1 つなら、必ずそれをもらう
    @Test
    func lastMissingRegularStampIsAlwaysGiven() {
        let owned = Array(Stamp.regularStamps.dropLast())
        for seed in UInt64(1)...20 {
            #expect(award(.animals, .easy, hasPass: false, owned: owned, seed: seed) == Stamp.regularStamps.last)
        }
    }

    /// どの種でも、持っている通常のスタンプはもらわない
    @Test
    func ownedRegularStampsAreNeverGiven() {
        let owned = Array(Stamp.regularStamps.prefix(8))
        for seed in UInt64(1)...50 {
            let stamp = award(.hiragana, .easy, hasPass: false, owned: owned, seed: seed)
            #expect(stamp.map { !owned.contains($0) } == true, "種 \(seed)")
        }
    }

    /// 通常のスタンプは種によって選ばれるものが変わる（ランダム）
    @Test
    func regularStampIsRandom() {
        let picked = Set((1...20).compactMap { award(.hiragana, .easy, hasPass: false, seed: $0) })
        #expect(picked.count > 1)
    }

    /// Q7: パスを持っていて、ふつう・むずかしいをはじめてクリアすると、そのコースと難易度のパス専用のスタンプ
    @Test
    func firstPassClearGivesThePassStamp() {
        #expect(award(.animals, .normal, hasPass: true) == .pass(.animals, .silver))
        #expect(award(.animals, .hard, hasPass: true) == .pass(.animals, .gold))
        #expect(award(.hiragana, .normal, hasPass: true) == .pass(.hiragana, .silver))
        #expect(award(.hiragana, .hard, hasPass: true) == .pass(.hiragana, .gold))
    }

    /// Q7: 2 回目からは通常のスタンプ（ほかのコース・難易度のパス専用のスタンプは関係しない）
    @Test
    func secondPassClearGivesARegularStamp() throws {
        let stamp = try #require(award(.animals, .normal, hasPass: true, owned: [.pass(.animals, .silver)]))
        #expect(Stamp.regularStamps.contains(stamp))
        #expect(award(.animals, .hard, hasPass: true, owned: [.pass(.animals, .silver)]) == .pass(.animals, .gold))
        #expect(award(.hiragana, .normal, hasPass: true, owned: [.pass(.animals, .silver)]) == .pass(.hiragana, .silver))
    }

    /// 通常のスタンプが全部そろっていても、はじめてのパス専用のスタンプはもらえる
    @Test
    func passStampIsGivenEvenWhenRegularStampsAreComplete() {
        #expect(award(.hiragana, .hard, hasPass: true, owned: Stamp.regularStamps) == .pass(.hiragana, .gold))
    }

    /// 通常のスタンプが全部そろった後は、新しいスタンプは増えない（ほめ言葉だけ）
    @Test
    func noStampAfterCollectingEverything() {
        #expect(award(.animals, .easy, hasPass: false, owned: Stamp.regularStamps) == nil)
        let everything = Stamp.regularStamps + Stamp.passStamps
        #expect(award(.animals, .hard, hasPass: true, owned: everything) == nil)
        #expect(StampCollection(ids: Stamp.regularStamps.map(\.id)).hasAllRegularStamps)
    }

    /// パスの権利が無いとき（返金など）は、ふつう・むずかしいをクリアしてもパス専用のスタンプはもらわない（4 つの組み合わせすべて）
    @Test
    func noPassStampWithoutEntitlement() {
        for course in Course.allCases {
            for difficulty in [Difficulty.normal, .hard] {
                let stamp = award(course, difficulty, hasPass: false)
                #expect(stamp.map { Stamp.regularStamps.contains($0) } == true, "\(course) \(difficulty)")
                #expect(award(course, difficulty, hasPass: false, owned: Stamp.regularStamps) == nil, "全部そろった後")
            }
        }
    }

    /// 1 回のクリアで決まるのは 1 つだけで、同じ状態・同じ種なら同じスタンプ
    @Test
    func awardIsDeterministicForTheSameSeed() {
        let first = award(.animals, .easy, hasPass: false, seed: 9)
        let second = award(.animals, .easy, hasPass: false, seed: 9)
        #expect(first == second)
    }
}
