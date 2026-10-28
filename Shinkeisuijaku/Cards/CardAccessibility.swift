//
//  CardAccessibility.swift
//  Shinkeisuijaku
//
//  カードの VoiceOver の読み上げ（CLAUDE.md のコードレビュー観点の 7）。
//  裏のカードは「うら」と状態だけを読み、中身（絵の名前・文字）はラベルにも値にも出さない（読み上げで答えが分かってしまうため）。
//  表は絵の名前か ひらがなの文字、揃ったら値に「そろった」を足す。子ども向けの画面なので言葉はひらがな（絵の名前はカタカナの名前のまま）。
//  View から切り離した値の型にして、単体テストする。
//

import Foundation

/// カード 1 枚の読み上げ
struct CardAccessibility: Equatable {
    /// ラベル（裏は「うら」、表は絵の名前か ひらがなの文字）
    let label: String
    /// 値（揃ったら「そろった」。それ以外は nil で、何も足さない）
    let value: String?

    /// - Parameters:
    ///   - face: カードの表に出すもの（裏のときは読まない）
    ///   - isFaceUp: 表を見せているか（めくった・揃った・全部見せている・ヒント）。画面に見えているものだけを読む
    ///   - isMatched: ペアが揃ったか
    init(face: Card.Face, isFaceUp: Bool, isMatched: Bool) {
        guard isFaceUp else {
            label = String(localized: "うら")
            value = nil
            return
        }
        switch face {
        case let .picture(picture, _):
            label = picture.name
        case let .letter(letter):
            label = letter
        }
        value = isMatched ? String(localized: "そろった") : nil
    }
}
