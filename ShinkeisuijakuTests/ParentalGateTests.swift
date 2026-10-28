//
//  ParentalGateTests.swift
//  ShinkeisuijakuTests
//
//  保護者の確認の問題の作り方・入力の桁数の上限・答えの判定を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct ParentalGateTests {
    /// 問題はいつも 2 桁＋1 桁で、答えは 2 桁（上限 99）に収まる
    @Test(arguments: 0..<20)
    func questionIsTwoDigitsPlusOneDigit(seed: UInt64) {
        var generator = SeededRandomNumberGenerator(seed: seed)
        for _ in 0..<200 {
            let question = ParentalGateQuestion.make(using: &generator)
            #expect((10...99).contains(question.augend))
            #expect((1...9).contains(question.addend))
            #expect((10...ParentalGateQuestion.maxAnswer).contains(question.answer))
        }
    }

    /// 同じ種なら同じ問題を作る（撮影モードで種を固定できる）
    @Test
    func sameSeedMakesSameQuestion() {
        var first = SeededRandomNumberGenerator(seed: 7)
        var second = SeededRandomNumberGenerator(seed: 7)
        #expect(ParentalGateQuestion.make(using: &first) == ParentalGateQuestion.make(using: &second))
    }

    /// 直前の問題を渡すと、それとは違う問題を作る
    @Test(arguments: 0..<20)
    func questionDiffersFromPrevious(seed: UInt64) {
        var generator = SeededRandomNumberGenerator(seed: seed)
        var previous = ParentalGateQuestion.make(using: &generator)
        for _ in 0..<200 {
            let next = ParentalGateQuestion.make(excluding: previous, using: &generator)
            #expect(next != previous)
            previous = next
        }
    }

    /// 入力は 2 桁まで。3 桁目は無視する
    @Test
    func inputIsLimitedToTwoDigits() {
        var input = ParentalGateInput()
        input.append(1)
        input.append(2)
        input.append(3)
        #expect(ParentalGateInput.maxDigits == 2)
        #expect(input.text == "12")
        #expect(input.value == 12)
    }

    /// 先頭の 0 と 0〜9 でない数は入れない。2 桁目の 0 は入れる
    @Test
    func inputIgnoresLeadingZeroAndInvalidDigits() {
        var input = ParentalGateInput()
        input.append(0)
        input.append(10)
        input.append(-1)
        #expect(input.isEmpty)
        #expect(input.value == nil)
        input.append(2)
        input.append(0)
        #expect(input.value == 20)
    }

    /// 消すと最後の数字が 1 つ消える。空のときに消しても何も起きない
    @Test
    func deleteRemovesLastDigit() {
        var input = ParentalGateInput()
        input.deleteLast()
        #expect(input.isEmpty)
        input.append(4)
        input.append(5)
        input.deleteLast()
        #expect(input.text == "4")
        input.deleteLast()
        #expect(input.isEmpty)
        #expect(input.text.isEmpty)
    }

    /// 合っていたら通す（問題は変えない）
    @Test
    func correctAnswerPasses() {
        var gate = ParentalGate(question: ParentalGateQuestion(augend: 12, addend: 7))
        gate.enter(1)
        gate.enter(9)
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(gate.submit(using: &generator) == .passed)
        #expect(gate.question == ParentalGateQuestion(augend: 12, addend: 7))
    }

    /// 間違えたら、入れた答えを消して別の問題に変え、「答えが違います」を出す。数字を入れ始めたら消す
    @Test
    func wrongAnswerChangesQuestion() {
        let first = ParentalGateQuestion(augend: 12, addend: 7)
        var gate = ParentalGate(question: first)
        gate.enter(1)
        gate.enter(8)
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(gate.submit(using: &generator) == .wrong)
        #expect(gate.question != first)
        #expect(gate.input.isEmpty)
        #expect(gate.showsWrongNotice)
        gate.enter(3)
        #expect(!gate.showsWrongNotice)
    }

    /// 何も入れずに決定しても、問題は変えない
    @Test
    func emptySubmitDoesNothing() {
        let first = ParentalGateQuestion(augend: 30, addend: 5)
        var gate = ParentalGate(question: first)
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(gate.submit(using: &generator) == .empty)
        #expect(gate.question == first)
        #expect(!gate.showsWrongNotice)
    }

    /// 間違えた後に出た新しい問題に正しく答えれば通る
    @Test
    func newQuestionCanBePassedAfterWrongAnswer() throws {
        var generator = SeededRandomNumberGenerator(seed: 5)
        var gate = ParentalGate(using: &generator)
        gate.enter(1)
        #expect(gate.submit(using: &generator) == .wrong)
        for character in String(gate.question.answer) {
            gate.enter(try #require(character.wholeNumberValue))
        }
        #expect(gate.submit(using: &generator) == .passed)
    }
}
