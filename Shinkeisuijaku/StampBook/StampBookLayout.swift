//
//  StampBookLayout.swift
//  Shinkeisuijaku
//
//  スタンプちょうの並べ方（引き継ぎブックの 10 ページ・仕様書の「スタンプ」）。どの枠に何を出すか・集めた数・読み上げの言葉・スタンプの直径を、
//  持っているスタンプとパスの権利から決める。View から切り離した値の型と純粋な関数にして、単体テストで確かめる。
//

import CoreGraphics
import Foundation

/// スタンプちょうの並べ方
struct StampBookLayout: Equatable {
    /// 枠 1 つ。その枠に入るスタンプと、いまの状態
    struct Entry: Equatable {
        /// この枠に入るスタンプ（持っていなくても、枠ごとに決まっている）
        let stamp: Stamp
        /// いまの状態（もらった・まだ・鍵）
        let slot: StampSlot
    }

    /// 通常の枠の列の数（4 列 × 3 段）
    static let regularColumns = 4
    /// パス専用の枠の列の数（銀と金の 2 段に、どうぶつ・ひらがなの 2 つずつ）
    static let passColumns = 2

    /// パス専用の枠の並び。1 段目が銀（ふつう）、2 段目が金（むずかしい）で、段の中は どうぶつ・ひらがな の順
    static let passOrder: [Stamp] = StampRim.allCases.flatMap { rim in
        Course.allCases.map { Stamp.pass($0, rim) }
    }

    /// 通常の 12 枠（`Stamp.regularStamps` の順。枠の場所はスタンプごとに決まっていて、もらった順には詰めない）
    let regular: [Entry]
    /// パス専用の 4 枠（`passOrder` の順）
    let pass: [Entry]
    /// 集めた数（「5 / 12」の 5）。通常のスタンプだけを数える（仕様書の「5 / 12」の 12 は通常の枠の数のため）
    let collectedCount: Int

    /// 集めた数の分母（「5 / 12」の 12）
    var totalCount: Int {
        regular.count
    }

    /// 持っているスタンプとパスの権利から並べる。
    /// - Parameter hasPass: パスの権利があるか。無いときは、まだのパス専用の枠に鍵を出す（仕様書の「購入前は、鍵のマークの枠で示す」）。
    ///   返金などで権利が無くなっても、もらったパス専用のスタンプはそのまま出す（記録は消さない）
    init(owned: StampCollection, hasPass: Bool) {
        regular = Stamp.regularStamps.map { stamp in
            Entry(stamp: stamp, slot: owned.contains(stamp) ? .owned(stamp) : .empty)
        }
        pass = Self.passOrder.map { stamp in
            if owned.contains(stamp) {
                Entry(stamp: stamp, slot: .owned(stamp))
            } else {
                Entry(stamp: stamp, slot: hasPass ? .empty : .locked)
            }
        }
        collectedCount = owned.regularCount
    }

    /// パス専用の枠を段に分けたもの（1 段目が銀、2 段目が金）
    var passRows: [[Entry]] {
        stride(from: 0, to: pass.count, by: Self.passColumns).map { start in
            Array(pass[start..<min(start + Self.passColumns, pass.count)])
        }
    }

    /// 通常の枠を段に分けたもの（4 つずつ 3 段）
    var regularRows: [[Entry]] {
        stride(from: 0, to: regular.count, by: Self.regularColumns).map { start in
            Array(regular[start..<min(start + Self.regularColumns, regular.count)])
        }
    }

    /// 集めた数の読み上げ（「5 / 12」を「スラッシュ」と読ませないよう、言葉にする）
    var countAccessibilityLabel: String {
        String(localized: "あつめた スタンプ \(totalCount) こ の うち \(collectedCount) こ")
    }

    /// 枠の読み上げ。もらったスタンプは名前（「ネコ」「どうぶつ ふつう」）、まだの通常の枠は場所の番号と「まだ」（「2ばんめ まだ」）、
    /// パス専用のまだ・鍵の枠は名前と状態（「どうぶつ むずかしい まだ」「ひらがな ふつう かぎ」）。
    /// まだの通常の枠は、どのスタンプが入るかを言わない（集める楽しみを残す）が、「まだ」が続いても今どこを読んでいるか分かるよう、場所の番号を付ける
    /// - Parameters:
    ///   - entry: 枠
    ///   - position: 通常の枠の場所の番号（上の段の左から 1・2・3…）。パス専用の枠では使わない
    static func accessibilityLabel(for entry: Entry, position: Int) -> String {
        switch (entry.stamp, entry.slot) {
        case (_, .owned):
            entry.stamp.name
        case (.regular, _):
            String(localized: "\(position)ばんめ まだ")
        case (.pass, .empty):
            String(localized: "\(entry.stamp.name) まだ")
        case (.pass, .locked):
            String(localized: "\(entry.stamp.name) かぎ")
        }
    }

    /// スタンプの直径。使える幅に 4 列が入る大きさを、72〜80 の範囲に収める（既定: 幅から決める）
    /// - Parameter width: 左右の余白を除いた、スタンプを並べられる幅
    static func diameter(forWidth width: CGFloat) -> CGFloat {
        let columns = CGFloat(regularColumns)
        let fitting = (width - Metrics.stampBookSpacing * (columns - 1)) / columns
        return min(max(fitting, Metrics.stampBookMinDiameter), Metrics.stampBookMaxDiameter)
    }
}
