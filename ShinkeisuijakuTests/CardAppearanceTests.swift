//
//  CardAppearanceTests.swift
//  ShinkeisuijakuTests
//
//  カードの 4 つの状態の見た目の決まり（引き継ぎブックの 6 ページ）を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import SwiftUI
import Testing

struct CardAppearanceTests {
    /// 裏のカードは、表が何でも同じ見た目（裏の中身が見た目から分からない）
    @Test
    func faceDownCardsLookTheSame() {
        let faces: [Card.Face] = [.letter("ね"), .picture(.cat, word: "ねこ"), .picture(.dog, word: nil)]
        for face in faces {
            let appearance = CardAppearance(face: face, isFaceUp: false, showsMatched: false)
            #expect(appearance.background == .back)
            #expect(appearance.backgroundColor == Palette.cardBack)
            #expect(appearance.word == nil)
        }
        #expect(CardAppearance(face: .letter("ね"), isFaceUp: false, showsMatched: true).background == .back)
    }

    /// 表は、文字のカードが温かい色の地、絵のカードが水色の地
    @Test
    func faceUpCardsUseTheirOwnBackground() {
        #expect(CardAppearance(face: .letter("ね"), isFaceUp: true, showsMatched: false).backgroundColor == Palette.cardLetter)
        let picture = CardAppearance(face: .picture(.cat, word: "ねこ"), isFaceUp: true, showsMatched: false)
        #expect(picture.backgroundColor == Palette.cardPicture)
        #expect(picture.word == nil, "揃うまで言葉は出さない")
    }

    /// 揃ったら緑の地になり、言葉はひらがなコースの絵のカードにだけ出る
    @Test
    func matchedCardsTurnGreenAndShowTheWord() {
        let letter = CardAppearance(face: .letter("ね"), isFaceUp: true, showsMatched: true)
        let hiraganaPicture = CardAppearance(face: .picture(.cat, word: "ねこ"), isFaceUp: true, showsMatched: true)
        let animalPicture = CardAppearance(face: .picture(.cat, word: nil), isFaceUp: true, showsMatched: true)
        #expect([letter, hiraganaPicture, animalPicture].allSatisfy { $0.backgroundColor == Palette.cardMatched })
        #expect(letter.word == nil)
        #expect(hiraganaPicture.word == "ねこ")
        #expect(animalPicture.word == nil)
    }
}
