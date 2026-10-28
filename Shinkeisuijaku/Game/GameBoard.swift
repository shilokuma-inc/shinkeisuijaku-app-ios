//
//  GameBoard.swift
//  Shinkeisuijaku
//
//  ゲームの盤面（カードの並び・めくり・ペアの判定）。時間を持たない値の型にして、規則だけを単体テストできるようにする。
//  タイマー・めくった回数・ミスの数は持たない（表示しないので、数えもしない）。
//

import Foundation

/// 1 枚のカード
struct Card: Identifiable, Equatable, Sendable {
    /// 表に出すもの
    enum Face: Equatable, Sendable {
        /// 絵。ひらがなコースの絵のカードは、揃ったときに現れる言葉を持つ
        case picture(Picture, word: String?)
        /// ひらがな 1 字（ひらがなコースの文字のカード）
        case letter(String)
    }

    /// 盤面の中で一意な番号（配った順）
    let id: Int
    /// ペアの番号。同じ番号の 2 枚がペア
    let pairID: Int
    let face: Face
    /// 表を向いているか（めくった・揃った）
    var isFaceUp = false
    /// ペアが揃ったか
    var isMatched = false
}

/// 1 枚めくった結果
enum FlipResult: Equatable, Sendable {
    /// めくれない（裏ではない・2 枚めくってある・知らないカード）
    case ignored
    /// 1 枚目をめくった
    case firstCard
    /// 2 枚目でペアが揃った
    case matched
    /// 2 枚目がハズレだった（`concealMismatch()` で裏に戻す）
    case mismatched
}

/// ゲームの盤面
struct GameBoard: Equatable, Sendable {
    private(set) var cards: [Card]

    init(cards: [Card]) {
        self.cards = cards
    }

    /// 揃っていないペアの数（「あと◯ペア」）
    var remainingPairs: Int {
        cards.filter { !$0.isMatched }.count / 2
    }

    /// 全部のペアが揃ったか
    var isCleared: Bool {
        cards.allSatisfy(\.isMatched)
    }

    /// めくってあって、まだ揃っていないカード（0〜2 枚）
    var unmatchedFaceUpCards: [Card] {
        cards.filter { $0.isFaceUp && !$0.isMatched }
    }

    /// カードを 1 枚めくる。めくってある 2 枚がハズレのまま残っているあいだは、ほかのカードをめくれない
    mutating func flip(cardID: Card.ID) -> FlipResult {
        guard let index = cards.firstIndex(where: { $0.id == cardID }),
              !cards[index].isFaceUp,
              unmatchedFaceUpCards.count < 2 else {
            return .ignored
        }
        cards[index].isFaceUp = true
        let open = unmatchedFaceUpCards
        guard open.count == 2 else {
            return .firstCard
        }
        guard open[0].pairID == open[1].pairID else {
            return .mismatched
        }
        for card in open {
            if let matchedIndex = cards.firstIndex(where: { $0.id == card.id }) {
                cards[matchedIndex].isMatched = true
            }
        }
        return .matched
    }

    /// ハズレの 2 枚を裏に戻す（× 表示や音は出さない）
    mutating func concealMismatch() {
        for index in cards.indices where cards[index].isFaceUp && !cards[index].isMatched {
            cards[index].isFaceUp = false
        }
    }
}

/// カードの配り方
enum GameDealer {
    /// コースの候補から難易度のペアの数だけランダムに選び、2 枚ずつ作ってランダムに並べる
    /// - Parameter generator: 乱数。テストと UI テストでは種を固定したものを渡す
    static func deal(
        course: Course,
        difficulty: Difficulty,
        using generator: inout some RandomNumberGenerator
    ) -> GameBoard {
        let pairCount = min(difficulty.pairCount, course.candidateCount)
        var faces: [(Card.Face, Card.Face)] = []
        switch course {
        case .animals:
            for picture in Course.animalPictures.shuffled(using: &generator).prefix(pairCount) {
                faces.append((.picture(picture, word: nil), .picture(picture, word: nil)))
            }
        case .hiragana:
            for pair in Course.hiraganaPairs.shuffled(using: &generator).prefix(pairCount) {
                faces.append((.letter(pair.letter), .picture(pair.picture, word: pair.word)))
            }
        }
        let unordered = faces.enumerated().flatMap { pairID, pair in
            [(pairID, pair.0), (pairID, pair.1)]
        }
        let cards = unordered.shuffled(using: &generator).enumerated().map { id, entry in
            Card(id: id, pairID: entry.0, face: entry.1)
        }
        return GameBoard(cards: cards)
    }
}

/// 種を固定できる乱数（SplitMix64）。テストと UI テストで、同じ並びを作るために使う
struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
