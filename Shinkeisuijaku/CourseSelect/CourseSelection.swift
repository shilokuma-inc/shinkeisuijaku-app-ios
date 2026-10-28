//
//  CourseSelection.swift
//  Shinkeisuijaku
//
//  コース選択のダイアログで決めること（仕様書の「画面と遷移」「ロックされた難易度を押したとき」・引き継ぎブックの 6・7 ページの「難易度ボタン」）。
//  どの難易度に鍵が付くか・押したときにゲームを始めるか「おうちの方に あけてもらってね」の案内を出すかを、
//  View から切り離した値の型と純粋な関数にして、単体テストで確かめる。
//

import Foundation

/// コース選択のダイアログの難易度ボタン 1 つに出すもの
struct CourseDifficultyOption: Equatable, Sendable {
    let difficulty: Difficulty
    /// 鍵のマークを付けるか（パスが要るのに権利が無い）
    let isLocked: Bool

    /// 右に小さく出すペアの数（「6ペア」）
    var pairsText: String {
        String(localized: "\(difficulty.pairCount)ペア")
    }

    /// VoiceOver の読み上げ（「ふつう 8ペア かぎ」）。鍵のマークは絵だけなので、状態を言葉でも伝える
    var accessibilityLabel: String {
        let words = [difficulty.name, pairsText] + (isLocked ? [String(localized: "かぎ")] : [])
        return words.joined(separator: " ")
    }

    /// VoiceOver のヒント（押すとどうなるか）。鍵の付いたものだけ、案内が出ることを伝える（鍵の無いものは押すと始まるので付けない）
    var accessibilityHint: String? {
        isLocked ? Self.lockedAccessibilityHint : nil
    }

    /// 鍵の付いた難易度（コース選択・クリアの次の難易度）を押したときのヒント（ゲームは始まらず、案内が出る）
    static var lockedAccessibilityHint: String {
        String(localized: "おすと おうちの方に あけてもらう あんないが でるよ")
    }
}

/// コース選択のダイアログで難易度を押したときにすること
enum CourseSelectResult: Equatable, Sendable {
    /// ダイアログを閉じて、そのコースと難易度のゲームを始める
    case start(GameChoice)
    /// ゲームは始めず、ダイアログの中に「おうちの方に あけてもらってね」を出す（値段と購入の画面は子どもに見せない）
    case showLockedGuide
}

/// 出しているコース選択のダイアログの状態（どのコースか・鍵の付いた難易度を押したか）
struct CourseSelection: Equatable, Sendable {
    let course: Course
    /// 最後に押した鍵の付いた難易度（案内を出している。押していなければ nil）。
    /// 購入の流れ（タスク 19）で、購入が終わったら押した難易度をすぐ始めるために覚えておく
    private(set) var lockedDifficulty: Difficulty?

    init(course: Course) {
        self.course = course
    }

    /// 難易度に鍵が付くか（ふつう・むずかしいは、パスの権利が無ければ鍵。購入後は付かない）
    static func isLocked(_ difficulty: Difficulty, hasPass: Bool) -> Bool {
        difficulty.requiresPass && !hasPass
    }

    /// 上から並べる難易度ボタン（やさしい・ふつう・むずかしい）
    static func options(hasPass: Bool) -> [CourseDifficultyOption] {
        Difficulty.allCases.map { CourseDifficultyOption(difficulty: $0, isLocked: isLocked($0, hasPass: hasPass)) }
    }

    /// 難易度を押したときにすることを決める。鍵が付いていれば押したものを覚えて案内を出し、無ければゲームを始める
    mutating func select(_ difficulty: Difficulty, hasPass: Bool) -> CourseSelectResult {
        if Self.isLocked(difficulty, hasPass: hasPass) {
            lockedDifficulty = difficulty
            return .showLockedGuide
        }
        lockedDifficulty = nil
        return .start(GameChoice(course: course, difficulty: difficulty))
    }

    /// 「おうちの方に あけてもらってね」を出すか（鍵の付いた難易度を押した後。ダイアログを出したままパスを買ったら消す）
    func showsLockedGuide(hasPass: Bool) -> Bool {
        guard let lockedDifficulty else {
            return false
        }
        return Self.isLocked(lockedDifficulty, hasPass: hasPass)
    }
}
