//
//  CardAccessibilityTests.swift
//  ShinkeisuijakuTests
//
//  カードと「あと◯ペア」の VoiceOver の読み上げを確かめる。裏のカードの中身は読み上げに出さない。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct CardAccessibilityTests {
    /// 裏のカードは、表が何でも「うら」だけを読む（絵の名前・文字・言葉をラベルにも値にも出さない）
    @Test
    func faceDownCardsReadOnlyTheirState() {
        let faces: [Card.Face] = [.letter("ね"), .picture(.cat, word: "ねこ"), .picture(.dog, word: nil)]
        for face in faces {
            let accessibility = CardAccessibility(face: face, isFaceUp: false, isMatched: false)
            #expect(accessibility == CardAccessibility(face: .letter("あ"), isFaceUp: false, isMatched: false))
            #expect(accessibility.label == "うら")
            #expect(accessibility.value == nil)
        }
    }

    /// 表のカードは、絵の名前か ひらがなの文字を読む
    @Test
    func faceUpCardsReadTheirContent() {
        #expect(CardAccessibility(face: .picture(.cat, word: nil), isFaceUp: true, isMatched: false).label == "ネコ")
        #expect(CardAccessibility(face: .picture(.star, word: "ほし"), isFaceUp: true, isMatched: false).label == "ホシ")
        let letter = CardAccessibility(face: .letter("ね"), isFaceUp: true, isMatched: false)
        #expect(letter.label == "ね")
        #expect(letter.value == nil, "揃うまでは状態を足さない")
    }

    /// 揃ったカードは、中身に「そろった」を足す（緑の色だけに頼らない）
    @Test
    func matchedCardsSayTheyMatched() {
        let matched = CardAccessibility(face: .picture(.fox, word: "きつね"), isFaceUp: true, isMatched: true)
        #expect(matched.label == "キツネ")
        #expect(matched.value == "そろった")
    }

    /// 「あと◯ペア」の札は、コース名・あと・数・ペアを 1 つにまとめて読む
    @Test
    func remainingPairsLabelReadsAsOneSentence() {
        #expect(PlayScreen.remainingPairsLabel(course: .hiragana, remainingPairs: 4) == "ひらがな あと 4 ペア")
        #expect(PlayScreen.remainingPairsLabel(course: .animals, remainingPairs: 10) == "どうぶつ あと 10 ペア")
    }
}
