//
//  Course.swift
//  Shinkeisuijaku
//
//  コース・難易度・絵の種類と、ひらがなコースの組。仕様書の「コースとゲームルール」の表を写す。
//

import Foundation

/// 絵の種類。rawValue は絵の SVG（Discussion #4 の Q1 の添付）の `<g id>` と同じ
enum Picture: String, CaseIterable, Codable, Sendable {
    case cat
    case dog
    case rabbit
    case panda
    case frog
    case chick
    case fox
    case penguin
    case apple
    case strawberry
    case bear
    case suika
    case star

    /// 絵の名前（カタカナ）。表のカードの読み上げなどに使う
    var name: String {
        switch self {
        case .cat: String(localized: "ネコ")
        case .dog: String(localized: "イヌ")
        case .rabbit: String(localized: "ウサギ")
        case .panda: String(localized: "パンダ")
        case .frog: String(localized: "カエル")
        case .chick: String(localized: "ヒヨコ")
        case .fox: String(localized: "キツネ")
        case .penguin: String(localized: "ペンギン")
        case .apple: String(localized: "リンゴ")
        case .strawberry: String(localized: "イチゴ")
        case .bear: String(localized: "クマ")
        case .suika: String(localized: "スイカ")
        case .star: String(localized: "ホシ")
        }
    }
}

/// ひらがなコースの 1 組（文字のカードと絵のカードがペアになる）
struct HiraganaPair: Equatable, Sendable {
    /// 文字のカードに出すひらがな 1 字
    let letter: String
    /// 絵のカードの絵
    let picture: Picture
    /// ペアが揃ったときに絵のカードに現れる言葉
    let word: String
}

/// コース
enum Course: String, CaseIterable, Codable, Sendable {
    /// 同じ絵のペアを探す
    case animals
    /// 文字のカードと絵のカードをペアにする
    case hiragana

    /// コースの名前（ひらがな）
    var name: String {
        switch self {
        case .animals: String(localized: "どうぶつ")
        case .hiragana: String(localized: "ひらがな")
        }
    }

    /// どうぶつコースの絵の候補（仕様書の 10 種類。毎回この中から選ぶ）
    static let animalPictures: [Picture] = [.cat, .fox, .panda, .frog, .apple, .chick, .penguin, .rabbit, .dog, .strawberry]

    /// ひらがなコースの組の候補（仕様書の 10 組。濁点・半濁点のある字は使わない）
    static let hiraganaPairs: [HiraganaPair] = [
        HiraganaPair(letter: "ね", picture: .cat, word: "ねこ"),
        HiraganaPair(letter: "か", picture: .frog, word: "かえる"),
        HiraganaPair(letter: "き", picture: .fox, word: "きつね"),
        HiraganaPair(letter: "り", picture: .apple, word: "りんご"),
        HiraganaPair(letter: "す", picture: .suika, word: "すいか"),
        HiraganaPair(letter: "ひ", picture: .chick, word: "ひよこ"),
        HiraganaPair(letter: "ほ", picture: .star, word: "ほし"),
        HiraganaPair(letter: "う", picture: .rabbit, word: "うさぎ"),
        HiraganaPair(letter: "い", picture: .dog, word: "いぬ"),
        HiraganaPair(letter: "く", picture: .bear, word: "くま")
    ]

    /// コースの候補の数（選べるペアの上限）
    var candidateCount: Int {
        switch self {
        case .animals: Self.animalPictures.count
        case .hiragana: Self.hiraganaPairs.count
        }
    }
}

/// 難易度
enum Difficulty: String, CaseIterable, Codable, Sendable {
    /// やさしい（6 ペア・無料）
    case easy
    /// ふつう（8 ペア・パスで開放）
    case normal
    /// むずかしい（10 ペア・パスで開放）
    case hard

    /// ペアの数
    var pairCount: Int {
        switch self {
        case .easy: 6
        case .normal: 8
        case .hard: 10
        }
    }

    /// 難易度の名前（ひらがな）
    var name: String {
        switch self {
        case .easy: String(localized: "やさしい")
        case .normal: String(localized: "ふつう")
        case .hard: String(localized: "むずかしい")
        }
    }

    /// パスが要るか（やさしいは無料）
    var requiresPass: Bool {
        self != .easy
    }

    /// 次の難易度。むずかしいの次は無い
    var next: Difficulty? {
        switch self {
        case .easy: .normal
        case .normal: .hard
        case .hard: nil
        }
    }
}
