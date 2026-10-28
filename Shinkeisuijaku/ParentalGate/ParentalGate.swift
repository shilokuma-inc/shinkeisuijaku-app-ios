//
//  ParentalGate.swift
//  Shinkeisuijaku
//
//  保護者の確認（Discussion #4 の Q5・仕様書の「ロックされた難易度を押したとき」）の問題と答えの判定。
//  2 桁＋1 桁の足し算を出し、テンキーで入れた答えを確かめる。間違えたら別の問題に変える。
//  View から切り離した値の型と純粋な関数にして、乱数を注入して単体テストする。
//

import Foundation

/// 保護者の確認の問題（2 桁＋1 桁の足し算）
struct ParentalGateQuestion: Equatable, Sendable {
    /// 足される数（2 桁）
    let augend: Int
    /// 足す数（1 桁）
    let addend: Int

    /// 足される数の範囲（2 桁）
    static let augendRange = 10...98
    /// 足す数の範囲（1 桁。0 を足すと計算にならないので 1 から）
    static let addendRange = 1...9
    /// 答えの上限。答えを 2 桁に収め、入力の桁数を 2 にする（資料に無いので決めた。3 桁の答えは足し算の手間が変わらないので出さない）
    static let maxAnswer = 99

    /// 答え
    var answer: Int {
        augend + addend
    }

    /// 問題を作る。`previous` を渡すと、それとは違う問題を返す（間違えたときに同じ問題を続けて出さない）
    /// - Parameters:
    ///   - previous: 直前に出した問題
    ///   - generator: 数を選ぶ乱数
    static func make(
        excluding previous: ParentalGateQuestion? = nil,
        using generator: inout some RandomNumberGenerator
    ) -> ParentalGateQuestion {
        while true {
            let augend = Int.random(in: augendRange, using: &generator)
            // 答えが上限を超えないよう、足す数の上限を足される数に合わせて下げる（98 なら 1 だけ）
            let addend = Int.random(in: addendRange.lowerBound...min(addendRange.upperBound, maxAnswer - augend), using: &generator)
            let question = ParentalGateQuestion(augend: augend, addend: addend)
            // 問題は 700 通り以上あるので、同じものを引き直すことはまれ
            if question != previous {
                return question
            }
        }
    }
}

/// テンキーで入れている答え
struct ParentalGateInput: Equatable, Sendable {
    /// 入れた数字（左から）
    private(set) var digits: [Int] = []

    /// 入れられる桁数の上限（答えの上限の桁数）
    static let maxDigits = String(ParentalGateQuestion.maxAnswer).count

    /// まだ何も入れていないか
    var isEmpty: Bool {
        digits.isEmpty
    }

    /// 入れた答えの数（何も入れていなければ nil）
    var value: Int? {
        isEmpty ? nil : digits.reduce(0) { $0 * 10 + $1 }
    }

    /// 画面に出す文字（「12」など。何も入れていなければ空）
    var text: String {
        digits.map(String.init).joined()
    }

    /// 数字を 1 つ足す。桁数の上限に達しているとき・0〜9 でないとき・先頭の 0（答えは 11 以上なので要らない）は無視する
    mutating func append(_ digit: Int) {
        guard (0...9).contains(digit), digits.count < Self.maxDigits, !(digits.isEmpty && digit == 0) else {
            return
        }
        digits.append(digit)
    }

    /// 最後の数字を 1 つ消す（何も入れていなければ何もしない）
    mutating func deleteLast() {
        _ = digits.popLast()
    }
}

/// 決定を押した結果
enum ParentalGateResult: Equatable, Sendable {
    /// 合っていた（呼び出し元へ通す）
    case passed
    /// 間違えていた（別の問題に変えた）
    case wrong
    /// まだ何も入れていない（何もしない）
    case empty
}

/// 保護者の確認の状態（今の問題と入れている答え）
struct ParentalGate: Equatable, Sendable {
    private(set) var question: ParentalGateQuestion
    private(set) var input = ParentalGateInput()
    /// 間違えて問題を変えた直後か（「答えが違います」を出す。数字を入れ始めたら消す）
    private(set) var showsWrongNotice = false

    init(question: ParentalGateQuestion) {
        self.question = question
    }

    /// 乱数で最初の問題を作る
    init(using generator: inout some RandomNumberGenerator) {
        self.init(question: .make(using: &generator))
    }

    /// 数字を 1 つ入れる
    mutating func enter(_ digit: Int) {
        input.append(digit)
        showsWrongNotice = false
    }

    /// 最後の数字を 1 つ消す
    mutating func delete() {
        input.deleteLast()
    }

    /// 答えを確かめる。間違えていたら、入れた答えを消して別の問題に変える
    mutating func submit(using generator: inout some RandomNumberGenerator) -> ParentalGateResult {
        guard let value = input.value else {
            return .empty
        }
        if value == question.answer {
            return .passed
        }
        question = .make(excluding: question, using: &generator)
        input = ParentalGateInput()
        showsWrongNotice = true
        return .wrong
    }
}

/// 保護者の確認の読み上げの文（保護者向けなので漢字を含む大人向けの文）。
/// 数字を押すたびに今の入力を、間違えたときに新しい問題を読み上げる（画面を見なくても、何を入れたか・次に何を解くかが分かるように）
enum ParentalGateSpeech {
    /// 問題の読み上げ（「問題 12 足す 7」。「＋」「＝ ？」を記号のまま読ませない）
    static func question(_ question: ParentalGateQuestion) -> String {
        String(localized: "問題 \(question.augend) 足す \(question.addend)")
    }

    /// 答えの欄の値（「12」。何も入れていなければ「未入力」）
    static func inputValue(_ input: ParentalGateInput) -> String {
        input.isEmpty ? String(localized: "未入力") : input.text
    }

    /// 数字を押した・消したあとに読み上げる、今の入力（「入力 12」「入力 未入力」）
    static func inputChanged(_ input: ParentalGateInput) -> String {
        String(localized: "入力 \(inputValue(input))")
    }

    /// 間違えたときに読み上げる文（「答えが違います。新しい問題は 34 足す 5 です。」）
    static func wrong(next question: ParentalGateQuestion) -> String {
        String(localized: "答えが違います。新しい問題は \(question.augend) 足す \(question.addend) です。")
    }
}
