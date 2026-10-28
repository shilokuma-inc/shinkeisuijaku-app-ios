//
//  AppData.swift
//  Shinkeisuijaku
//
//  端末の中だけに保存するデータ。外へは送らない。
//  保存の形には版を持たせ、項目が欠けていたり知らない値が入っていたりしても、その項目だけ既定値にして読む。
//

import Foundation

/// 端末に保存するデータ
struct AppData: Equatable, Sendable {
    /// 今の保存の形の版。項目の意味を変えるときに上げ、`init(from:)` で古い版から読み替える
    static let currentSchemaVersion = 1

    /// 持っているスタンプの識別子（もらった順）。スタンプの種類はスタンプのモデルが決める
    var ownedStampIDs: [String] = []
    /// パスを持っているかのキャッシュ。起動直後の表示を早くするためだけに使い、権利の正は StoreKit
    var hasPassCache = false
    /// 前回遊んだコース（「あそぶ」で始めるコース）
    var lastCourse: Course = .animals
    /// 前回遊んだ難易度
    var lastDifficulty: Difficulty = .easy
    /// 1 回でもクリアしたか（クリアするまでは、起動するとすぐゲームが始まる）
    var hasClearedOnce = false

    /// 初めて起動したときのデータ
    static let initial = AppData()
}

extension AppData: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case ownedStampIDs
        case hasPassCache
        case lastCourse
        case lastDifficulty
        case hasClearedOnce
    }

    /// 項目ごとに読み、読めない項目は既定値にする（1 つの項目のせいで全部を失わないため）
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let initial = AppData.initial
        ownedStampIDs = (try? container.decodeIfPresent([String].self, forKey: .ownedStampIDs)) ?? initial.ownedStampIDs
        hasPassCache = (try? container.decodeIfPresent(Bool.self, forKey: .hasPassCache)) ?? initial.hasPassCache
        if let course = try? container.decodeIfPresent(Course.self, forKey: .lastCourse) {
            lastCourse = course
            lastDifficulty = (try? container.decodeIfPresent(Difficulty.self, forKey: .lastDifficulty)) ?? initial.lastDifficulty
        } else {
            // コースが読めないときは難易度も既定値にする（遊んだことのない組み合わせで始めないため）
            lastCourse = initial.lastCourse
            lastDifficulty = initial.lastDifficulty
        }
        hasClearedOnce = (try? container.decodeIfPresent(Bool.self, forKey: .hasClearedOnce)) ?? initial.hasClearedOnce
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(ownedStampIDs, forKey: .ownedStampIDs)
        try container.encode(hasPassCache, forKey: .hasPassCache)
        try container.encode(lastCourse, forKey: .lastCourse)
        try container.encode(lastDifficulty, forKey: .lastDifficulty)
        try container.encode(hasClearedOnce, forKey: .hasClearedOnce)
    }

    /// すべての項目を読めるか（欠けている項目はよい）。読めない項目があれば、保存の入れ物が元のデータを退避する
    /// （`init(from:)` はその項目を既定値にするので、次の保存で元の値が消えてしまうため）
    static func isFullyReadable(_ data: Data) -> Bool {
        struct Strict: Decodable {
            let schemaVersion: Int?
            let ownedStampIDs: [String]?
            let hasPassCache: Bool?
            let lastCourse: Course?
            let lastDifficulty: Difficulty?
            let hasClearedOnce: Bool?
        }
        return (try? JSONDecoder().decode(Strict.self, from: data)) != nil
    }

    /// 保存されている形の版（無ければ nil）。新しい版のアプリが書いたデータかを見分けるために使う
    static func schemaVersion(of data: Data) -> Int? {
        struct Header: Decodable {
            let schemaVersion: Int?
        }
        return (try? JSONDecoder().decode(Header.self, from: data))?.schemaVersion
    }
}
