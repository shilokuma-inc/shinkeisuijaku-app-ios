//
//  AppDataStoreTests.swift
//  ShinkeisuijakuTests
//
//  端末内の保存を確かめる。`UserDefaults` はテストごとに別の suite を作って消し、アプリの保存を汚さない。
//

import Foundation
@testable import Shinkeisuijaku
import Testing

struct AppDataStoreTests {
    /// テストだけで使う `UserDefaults`。テストの終わりに `removeSuite()` で消す
    private final class TemporaryDefaults {
        let name = "AppDataStoreTests.\(UUID().uuidString)"
        let defaults: UserDefaults

        init() {
            defaults = UserDefaults(suiteName: name) ?? .standard
        }

        func removeSuite() {
            defaults.removePersistentDomain(forName: name)
        }
    }

    private let sample = AppData(
        ownedStampIDs: ["cat", "passAnimalsNormal"],
        hasPassCache: true,
        lastCourse: .hiragana,
        lastDifficulty: .hard,
        hasClearedOnce: true
    )

    /// 何も保存していなければ、初めて起動したときのデータ
    @Test
    func loadsInitialDataWhenEmpty() {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        #expect(store.load() == .initial)
        #expect(AppData.initial.lastCourse == .animals)
        #expect(AppData.initial.lastDifficulty == .easy)
        #expect(!AppData.initial.hasClearedOnce)
        #expect(!AppData.initial.hasPassCache)
        #expect(AppData.initial.ownedStampIDs.isEmpty)
    }

    /// 保存したデータを、別の入れ物からでも同じ値で読める
    @Test
    func savedDataRoundTrips() {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        UserDefaultsAppDataStore(defaults: temporary.defaults).save(sample)
        #expect(UserDefaultsAppDataStore(defaults: temporary.defaults).load() == sample)
    }

    /// 保存の形に版が入る
    @Test
    func savedDataHasSchemaVersion() throws {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        UserDefaultsAppDataStore(defaults: temporary.defaults).save(sample)
        let data = try #require(temporary.defaults.data(forKey: UserDefaultsAppDataStore.defaultKey))
        #expect(AppData.schemaVersion(of: data) == AppData.currentSchemaVersion)
    }

    /// JSON として読めないデータは既定値で起動し、元のデータは別のキーに残す（捨てない）
    @Test
    func unreadableDataFallsBackAndIsKept() {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        let broken = Data("これは JSON ではない".utf8)
        temporary.defaults.set(broken, forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        #expect(store.load() == .initial)
        #expect(temporary.defaults.data(forKey: store.unreadableBackupKey) == broken)
    }

    /// 欠けている項目・知らない値の項目だけを既定値にし、ほかの項目は読む
    @Test
    func partiallyReadableDataKeepsReadableFields() {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = #"{"schemaVersion":1,"ownedStampIDs":["dog"],"lastCourse":"kazu","lastDifficulty":"normal","hasClearedOnce":"yes"}"#
        temporary.defaults.set(Data(json.utf8), forKey: UserDefaultsAppDataStore.defaultKey)
        let loaded = UserDefaultsAppDataStore(defaults: temporary.defaults).load()
        #expect(loaded.ownedStampIDs == ["dog"])
        #expect(loaded.lastCourse == .animals, "知らないコースは既定値")
        #expect(loaded.lastDifficulty == .normal)
        #expect(!loaded.hasClearedOnce, "型の違う値は既定値")
        #expect(!loaded.hasPassCache, "欠けている項目は既定値")
    }

    /// 新しい版のアプリが書いたデータは、読める項目だけ読み、元のデータも残す
    @Test
    func newerSchemaIsReadAndKept() {
        let temporary = TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = #"{"schemaVersion":99,"hasClearedOnce":true,"somethingNew":[1,2]}"#
        temporary.defaults.set(Data(json.utf8), forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        #expect(store.load().hasClearedOnce)
        #expect(temporary.defaults.data(forKey: store.unreadableBackupKey) == Data(json.utf8))
    }

    /// メモリ上の入れ物は保存した値をそのまま返す
    @Test
    func inMemoryStoreKeepsSavedData() {
        let store = InMemoryAppDataStore()
        #expect(store.load() == .initial)
        store.save(sample)
        #expect(store.load() == sample)
        #expect(store.saveCount == 1)
    }

    /// Unit テストのホスト・UI テスト・撮影モードでは、実際の `UserDefaults` を使わない
    @Test
    func factoryUsesInMemoryStoreOutsideNormalLaunch() {
        #expect(AppDataStoreFactory.make(arguments: [], environment: ["XCTestConfigurationFilePath": "/tmp/x"]) is InMemoryAppDataStore)
        #expect(AppDataStoreFactory.make(arguments: ["-uiTesting"], environment: [:]) is InMemoryAppDataStore)
        #expect(AppDataStoreFactory.make(arguments: ["-screenshot-demo"], environment: [:]) is InMemoryAppDataStore)
        #expect(AppDataStoreFactory.make(arguments: [], environment: [:]) is UserDefaultsAppDataStore)
    }
}
