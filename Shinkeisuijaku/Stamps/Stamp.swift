//
//  Stamp.swift
//  Shinkeisuijaku
//
//  スタンプの種類と、クリアしたときのもらい方。仕様書の「スタンプ」と Discussion #4 の Q7 の答えを写す。
//  もらい方は、View と保存から切り離した純粋な関数にする（乱数は注入する）。
//

import Foundation

/// パス専用のスタンプのふち
enum StampRim: String, CaseIterable, Sendable {
    /// 銀のふち（ふつうをクリア）
    case silver
    /// 金のふち（むずかしいをクリア）
    case gold

    /// 難易度のふち。やさしいにはパス専用のスタンプが無い
    init?(difficulty: Difficulty) {
        switch difficulty {
        case .easy: return nil
        case .normal: self = .silver
        case .hard: self = .gold
        }
    }

    /// このふちをもらう難易度（銀は ふつう、金は むずかしい）
    var difficulty: Difficulty {
        switch self {
        case .silver: .normal
        case .gold: .hard
        }
    }
}

/// スタンプ 1 つ
enum Stamp: Hashable, Sendable {
    /// 通常のスタンプ（12 種類の絵。クリアするたびに、まだ持っていないものから 1 つ）
    case regular(Picture)
    /// パス専用のスタンプ（コースのシンボルに銀か金のふち。どうぶつはネコ、ひらがなは「あ」）
    case pass(Course, StampRim)

    /// 通常のスタンプの絵（仕様書の 12 種類。ホシは入らない）
    static let regularPictures: [Picture] = [
        .cat, .dog, .rabbit, .panda, .frog, .chick, .fox, .penguin, .apple, .strawberry, .bear, .suika
    ]

    /// 通常のスタンプ 12 個（スタンプちょうの並び順）
    static let regularStamps: [Stamp] = regularPictures.map(Stamp.regular)

    /// パス専用のスタンプ 4 個（どうぶつの銀・金、ひらがなの銀・金の順）
    static let passStamps: [Stamp] = Course.allCases.flatMap { course in
        StampRim.allCases.map { Stamp.pass(course, $0) }
    }

    /// 保存に使う識別子（`AppData.ownedStampIDs` に入れる）。一度出したら変えない
    var id: String {
        switch self {
        case let .regular(picture):
            "regular.\(picture.rawValue)"
        case let .pass(course, rim):
            "pass.\(course.rawValue).\(rim.rawValue)"
        }
    }

    /// スタンプの名前（読み上げに使う）。通常は絵の名前（「ネコ」）、パス専用はコースと難易度（「どうぶつ ふつう」）
    var name: String {
        switch self {
        case let .regular(picture):
            picture.name
        case let .pass(course, rim):
            String(localized: "\(course.name) \(rim.difficulty.name)")
        }
    }

    /// 識別子からスタンプを作る。知らない識別子なら nil（新しい版のアプリが書いたものなど）
    init?(id: String) {
        guard let stamp = (Self.regularStamps + Self.passStamps).first(where: { $0.id == id }) else {
            return nil
        }
        self = stamp
    }
}

/// 持っているスタンプ
struct StampCollection: Equatable, Sendable {
    /// 持っているスタンプ（もらった順）
    private(set) var stamps: [Stamp]

    /// 保存の識別子から作る。知らない識別子と重なりは除く（知らないものも保存の側には残る）
    init(ids: [String]) {
        var stamps: [Stamp] = []
        for stamp in ids.compactMap(Stamp.init(id:)) where !stamps.contains(stamp) {
            stamps.append(stamp)
        }
        self.stamps = stamps
    }

    /// 持っているか
    func contains(_ stamp: Stamp) -> Bool {
        stamps.contains(stamp)
    }

    /// 集めた通常のスタンプの数（スタンプちょうの「5 / 12」の 5）
    var regularCount: Int {
        stamps.filter { if case .regular = $0 { true } else { false } }.count
    }

    /// まだ持っていない通常のスタンプ
    var missingRegularStamps: [Stamp] {
        Stamp.regularStamps.filter { !contains($0) }
    }

    /// 通常のスタンプが全部そろったか
    var hasAllRegularStamps: Bool {
        missingRegularStamps.isEmpty
    }
}

/// クリアしたときのスタンプのもらい方
enum StampRules {
    /// クリアの結果から、もらうスタンプを決める（1 回のクリアでもらうのは 1 つまで）。
    ///
    /// Q7: パスを持っていて、ふつう・むずかしいをそのコースと難易度ではじめてクリアした（パス専用のスタンプをまだ持っていない）ときは、
    /// パス専用のスタンプ。それ以外は、まだ持っていない通常のスタンプからランダムに 1 つ。通常のスタンプが全部そろった後は nil（ほめ言葉だけ）。
    /// - Parameters:
    ///   - hasPass: パスの権利があるか（返金などで権利が無いときは、パス専用のスタンプをもらわない）。
    ///     権利が無い時期にふつう・むずかしいをクリアしても通常のスタンプになり、パスを買い直した後にクリアすると、パス専用のスタンプをもらえる
    ///   - generator: 通常のスタンプを選ぶ乱数。テストでは種を固定したものを渡す
    static func award(
        course: Course,
        difficulty: Difficulty,
        hasPass: Bool,
        owned: StampCollection,
        using generator: inout some RandomNumberGenerator
    ) -> Stamp? {
        if hasPass, let rim = StampRim(difficulty: difficulty) {
            let passStamp = Stamp.pass(course, rim)
            if !owned.contains(passStamp) {
                return passStamp
            }
        }
        return owned.missingRegularStamps.randomElement(using: &generator)
    }
}
