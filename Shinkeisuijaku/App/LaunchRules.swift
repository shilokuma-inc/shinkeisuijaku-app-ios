//
//  LaunchRules.swift
//  Shinkeisuijaku
//
//  起動したときにどこから始めるかと、ホームの「あそぶ」で始めるゲームの決まり（仕様書の「画面と遷移」）。
//  画面から切り離した純粋な関数にして、単体テストで確かめる。
//

import Foundation

/// 始めるゲームのコースと難易度
struct GameChoice: Equatable, Sendable {
    let course: Course
    let difficulty: Difficulty
}

/// 起動とホームの「あそぶ」の決まり
enum LaunchRules {
    /// 初回クリア前に起動したとき、すぐ始めるゲーム（どうぶつ・やさしい）
    static let firstGame = GameChoice(course: .animals, difficulty: .easy)

    /// 起動したときにホームを通らずゲームから始めるか（最初の 1 回をクリアするまで）
    static func startsWithGame(_ data: AppData) -> Bool {
        !data.hasClearedOnce
    }

    /// 起動したときに始めるゲーム。ホームから始めるときは nil
    static func launchGame(_ data: AppData) -> GameChoice? {
        startsWithGame(data) ? firstGame : nil
    }

    /// ホームの「あそぶ」で始めるゲーム。前回のコースと難易度で始め、
    /// 前回の難易度に鍵が付いている（返金などでパスの権利が無い）ときは、そのコースのやさしいで始める
    static func resumeGame(_ data: AppData, hasPass: Bool) -> GameChoice {
        let difficulty = data.lastDifficulty.requiresPass && !hasPass ? .easy : data.lastDifficulty
        return GameChoice(course: data.lastCourse, difficulty: difficulty)
    }
}
