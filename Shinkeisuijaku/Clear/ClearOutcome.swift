//
//  ClearOutcome.swift
//  Shinkeisuijaku
//
//  クリアしたときに決めること（もらうスタンプ・保存するデータ・クリアのダイアログに出すもの）。
//  View と保存から切り離した純粋な関数にして、単体テストする。点数・回数は持たない。
//

import Foundation

/// 1 回のクリアの結果
struct ClearOutcome: Equatable {
    let course: Course
    let difficulty: Difficulty
    /// もらったスタンプ（通常のスタンプが全部そろった後は nil。ほめ言葉だけ出す）
    let awardedStamp: Stamp?
    /// 保存するデータ（スタンプを足し、初回クリア済み・前回のコースと難易度を記録したもの）
    let data: AppData

    /// クリアの結果を決める（1 回のクリアでもらうスタンプは 1 つまで）
    /// - Parameters:
    ///   - data: クリアする前の保存データ
    ///   - hasPass: パスの権利があるか（StoreKit の権利。パス専用のスタンプをもらえるか）
    ///   - generator: 通常のスタンプを選ぶ乱数
    static func make(
        course: Course,
        difficulty: Difficulty,
        data: AppData,
        hasPass: Bool,
        using generator: inout some RandomNumberGenerator
    ) -> ClearOutcome {
        let owned = StampCollection(ids: data.ownedStampIDs)
        let stamp = StampRules.award(course: course, difficulty: difficulty, hasPass: hasPass, owned: owned, using: &generator)
        var updated = data
        if let stamp {
            updated.ownedStampIDs.append(stamp.id)
        }
        updated.hasClearedOnce = true
        updated.lastCourse = course
        updated.lastDifficulty = difficulty
        return ClearOutcome(course: course, difficulty: difficulty, awardedStamp: stamp, data: updated)
    }

    /// 次の難易度（むずかしいのときは nil で、ボタンを出さない）
    var nextDifficulty: Difficulty? {
        difficulty.next
    }

    /// 次の難易度に鍵が付いているか（パスが要るのに権利が無い）
    func isNextDifficultyLocked(hasPass: Bool) -> Bool {
        guard let next = nextDifficulty else {
            return false
        }
        return next.requiresPass && !hasPass
    }

    /// クリアのダイアログの大きなスタンプの読み上げ（「ネコ の スタンプ」「どうぶつ ふつう の とくべつな スタンプ」）。
    /// 通常のスタンプが全部そろった後（もらわなかった）は nil で、飾りのホシを読み上げない
    var stampAccessibilityLabel: String? {
        guard let awardedStamp else {
            return nil
        }
        switch awardedStamp {
        case .regular:
            return String(localized: "\(awardedStamp.name) の スタンプ")
        case .pass:
            return String(localized: "\(awardedStamp.name) の とくべつな スタンプ")
        }
    }

    /// 「もっと むずかしいのは おうちの方へ」を出すか（パスを買った後は出さない）
    static func showsParentsGuide(hasPass: Bool) -> Bool {
        !hasPass
    }
}
