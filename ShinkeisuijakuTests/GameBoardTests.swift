//
//  GameBoardTests.swift
//  ShinkeisuijakuTests
//
//  カードの配り方と、めくり・ペアの判定の規則を確かめる。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct GameBoardTests {
    /// 種を固定して配る
    private func deal(_ course: Course, _ difficulty: Difficulty, seed: UInt64 = 1) -> GameBoard {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return GameDealer.deal(course: course, difficulty: difficulty, using: &generator)
    }

    /// ペアの番号ごとの 2 枚
    private func pairs(of board: GameBoard) -> [[Card]] {
        Dictionary(grouping: board.cards, by: \.pairID).values.sorted { $0[0].pairID < $1[0].pairID }
    }

    // MARK: - 配り方

    /// 難易度のペアの数だけ、2 枚ずつ配る（どちらのコースも）
    @Test
    func dealsTwoCardsPerPair() {
        for course in Course.allCases {
            for difficulty in Difficulty.allCases {
                let board = deal(course, difficulty)
                #expect(board.cards.count == difficulty.pairCount * 2, "\(course) \(difficulty)")
                #expect(Set(board.cards.map(\.id)).count == board.cards.count)
                #expect(pairs(of: board).allSatisfy { $0.count == 2 })
                #expect(board.remainingPairs == difficulty.pairCount)
                #expect(board.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
            }
        }
    }

    /// どうぶつコースは同じ絵の 2 枚がペアで、絵は候補の 10 種類から重ならずに選ぶ
    @Test
    func animalPairsShareThePicture() {
        let board = deal(.animals, .hard)
        var pictures: [Picture] = []
        for pair in pairs(of: board) {
            guard case let .picture(first, word: nil) = pair[0].face else {
                Issue.record("どうぶつコースのカードが絵ではない: \(pair[0].face)")
                continue
            }
            #expect(pair[1].face == .picture(first, word: nil))
            pictures.append(first)
        }
        #expect(Set(pictures) == Set(Course.animalPictures))
    }

    /// ひらがなコースは文字のカードと絵のカードがペアで、組は仕様書の表どおり。絵のカードは揃ったときの言葉を持つ
    @Test
    func hiraganaPairsMatchLetterAndPicture() {
        let board = deal(.hiragana, .hard)
        var letters: [String] = []
        for pair in pairs(of: board) {
            let letter = pair.compactMap { card -> String? in
                if case let .letter(letter) = card.face {
                    return letter
                }
                return nil
            }
            let picture = pair.compactMap { card -> (Picture, String?)? in
                if case let .picture(picture, word) = card.face {
                    return (picture, word)
                }
                return nil
            }
            guard letter.count == 1, picture.count == 1 else {
                Issue.record("ひらがなコースのペアが文字と絵の 1 枚ずつではない: \(pair)")
                continue
            }
            let expected = Course.hiraganaPairs.first { $0.letter == letter[0] }
            #expect(expected != nil, "表に無い文字: \(letter[0])")
            #expect(picture[0].0 == expected?.picture)
            #expect(picture[0].1 == expected?.word)
            letters.append(letter[0])
        }
        #expect(Set(letters) == Set(Course.hiraganaPairs.map(\.letter)))
    }

    /// 同じ種なら同じ並び。種が違えば並びが変わる（毎回ランダム）
    @Test
    func dealIsRandomButReproducibleWithSeed() {
        let first = deal(.animals, .easy, seed: 42)
        let second = deal(.animals, .easy, seed: 42)
        #expect(first == second)
        let boards = (1...5).map { deal(.animals, .easy, seed: $0) }
        #expect(Set(boards.map { $0.cards.map { String(describing: $0.face) } }).count > 1)
    }

    /// やさしいでは候補の 10 種類から 6 種類を選び、種によって選ばれる絵が変わる
    @Test
    func easyChoosesSixOfTenPictures() {
        let chosen = (1...10).map { seed in
            Set(deal(.animals, .easy, seed: seed).cards.map { String(describing: $0.face) })
        }
        #expect(chosen.allSatisfy { $0.count == 6 })
        #expect(Set(chosen).count > 1)
    }

    // MARK: - めくり

    /// 同じペアの 2 枚をめくると揃い、「あと◯ペア」が減る
    @Test
    func flippingAPairMatchesIt() {
        var board = deal(.animals, .easy)
        let pair = pairs(of: board)[0]
        #expect(board.flip(cardID: pair[0].id) == .firstCard)
        #expect(board.flip(cardID: pair[1].id) == .matched)
        #expect(board.remainingPairs == 5)
        #expect(board.cards.filter(\.isMatched).map(\.id).sorted() == pair.map(\.id).sorted())
    }

    /// 違うペアの 2 枚はハズレ。裏に戻すまでは 3 枚目をめくれず、戻すと 2 枚とも裏になる
    @Test
    func mismatchBlocksUntilConcealed() {
        var board = deal(.animals, .easy)
        let all = pairs(of: board)
        #expect(board.flip(cardID: all[0][0].id) == .firstCard)
        #expect(board.flip(cardID: all[1][0].id) == .mismatched)
        #expect(board.flip(cardID: all[2][0].id) == .ignored)
        #expect(board.unmatchedFaceUpCards.count == 2)
        board.concealMismatch()
        #expect(board.unmatchedFaceUpCards.isEmpty)
        #expect(board.remainingPairs == 6)
        #expect(board.flip(cardID: all[2][0].id) == .firstCard)
    }

    /// 表のカード・揃ったカード・知らないカードはめくれない
    @Test
    func faceUpOrUnknownCardsAreIgnored() {
        var board = deal(.animals, .easy)
        let pair = pairs(of: board)[0]
        #expect(board.flip(cardID: pair[0].id) == .firstCard)
        #expect(board.flip(cardID: pair[0].id) == .ignored)
        #expect(board.flip(cardID: pair[1].id) == .matched)
        #expect(board.flip(cardID: pair[1].id) == .ignored)
        #expect(board.flip(cardID: 999) == .ignored)
    }

    /// 揃ったカードは、ハズレを裏に戻しても表のまま
    @Test
    func concealKeepsMatchedCards() {
        var board = deal(.hiragana, .easy)
        let all = pairs(of: board)
        _ = board.flip(cardID: all[0][0].id)
        _ = board.flip(cardID: all[0][1].id)
        _ = board.flip(cardID: all[1][0].id)
        _ = board.flip(cardID: all[2][0].id)
        board.concealMismatch()
        #expect(board.cards.filter(\.isFaceUp).map(\.id).sorted() == all[0].map(\.id).sorted())
    }

    /// 全部のペアを揃えるとクリア
    @Test
    func matchingAllPairsClearsTheBoard() {
        var board = deal(.hiragana, .normal)
        #expect(!board.isCleared)
        for pair in pairs(of: board) {
            _ = board.flip(cardID: pair[0].id)
            _ = board.flip(cardID: pair[1].id)
        }
        #expect(board.isCleared)
        #expect(board.remainingPairs == 0)
    }
}
