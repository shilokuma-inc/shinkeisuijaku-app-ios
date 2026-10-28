//
//  MotionPolicyTests.swift
//  ShinkeisuijakuTests
//
//  「視差効果を減らす」のときに止める動き（めくりの回転・揃ったときのふくらみ・ダイアログの出し入れ）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct MotionPolicyTests {
    /// 「視差効果を減らす」がオフなら、引き継ぎブックの動きをそのまま付ける
    @Test
    func standardMotionKeepsAllMovements() {
        let motion = MotionPolicy(reduceMotion: false)
        #expect(motion.rotatesOnFlip)
        #expect(motion.pulsesOnMatch)
        #expect(motion.fadesDialogs)
        #expect(motion.flipAnimation != nil)
        #expect(motion.dialogAnimation != nil)
    }

    /// 「視差効果を減らす」がオンなら、回転・ふくらみ・ダイアログの出し入れを止めて、切り替えるだけにする
    @Test
    func reducedMotionStopsMovements() {
        let motion = MotionPolicy(reduceMotion: true)
        #expect(!motion.rotatesOnFlip)
        #expect(!motion.pulsesOnMatch)
        #expect(!motion.fadesDialogs)
        #expect(motion.flipAnimation == nil)
        #expect(motion.dialogAnimation == nil)
    }

    /// 揃ってから緑になるまでの間は、「視差効果を減らす」でも同じ 0.35 秒（めくった表を見てから緑になる）
    @Test
    func matchDelayIsTheSameWithReducedMotion() {
        #expect(MotionPolicy(reduceMotion: false).matchDelay == 0.35)
        #expect(MotionPolicy(reduceMotion: true).matchDelay == 0.35)
    }
}
