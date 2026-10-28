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

        /// suite を作れないときは、アプリの `.standard` に書き込まないよう失敗させる
        init() throws {
            defaults = try #require(UserDefaults(suiteName: name))
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
    func loadsInitialDataWhenEmpty() throws {
        let temporary = try TemporaryDefaults()
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
    func savedDataRoundTrips() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        UserDefaultsAppDataStore(defaults: temporary.defaults).save(sample)
        #expect(UserDefaultsAppDataStore(defaults: temporary.defaults).load() == sample)
    }

    /// 保存の形に版が入る
    @Test
    func savedDataHasSchemaVersion() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        UserDefaultsAppDataStore(defaults: temporary.defaults).save(sample)
        let data = try #require(temporary.defaults.data(forKey: UserDefaultsAppDataStore.defaultKey))
        #expect(AppData.schemaVersion(of: data) == AppData.currentSchemaVersion)
    }

    /// JSON として読めないデータは既定値で起動し、元のデータは別のキーに残す（捨てない）
    @Test
    func unreadableDataFallsBackAndIsKept() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let broken = Data("これは JSON ではない".utf8)
        temporary.defaults.set(broken, forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        #expect(store.load() == .initial)
        #expect(store.unreadableBackups == [broken])
        store.save(sample)
        #expect(store.load() == sample)
        #expect(store.unreadableBackups == [broken], "既定値で起動して保存しても、退避したデータは残る")
    }

    /// 欠けている項目・知らない値の項目だけを既定値にし、ほかの項目は読む。読めない項目があれば元のデータを退避する
    @Test
    func partiallyReadableDataKeepsReadableFieldsAndBacksUp() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = Data(#"{"schemaVersion":1,"ownedStampIDs":["dog"],"lastDifficulty":"hard","hasClearedOnce":"yes"}"#.utf8)
        temporary.defaults.set(json, forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        let loaded = store.load()
        #expect(loaded.ownedStampIDs == ["dog"])
        #expect(loaded.lastCourse == .animals, "欠けている項目は既定値")
        #expect(loaded.lastDifficulty == .easy, "コースが読めないときは難易度も既定値")
        #expect(!loaded.hasClearedOnce, "型の違う値は既定値")
        #expect(store.unreadableBackups == [json], "型の違う値があるので元のデータを退避する")
    }

    /// 知らないコースのときは難易度も既定値にする（遊んだことのない組み合わせで始めない）
    @Test
    func unknownCourseResetsDifficulty() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = #"{"schemaVersion":1,"lastCourse":"kazu","lastDifficulty":"hard"}"#
        temporary.defaults.set(Data(json.utf8), forKey: UserDefaultsAppDataStore.defaultKey)
        let loaded = UserDefaultsAppDataStore(defaults: temporary.defaults).load()
        #expect(loaded.lastCourse == .animals)
        #expect(loaded.lastDifficulty == .easy)
    }

    /// スタンプの一覧が読めないとき、次に保存しても元のスタンプを失わない
    @Test
    func unreadableStampsAreNotLostAfterSave() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = Data(#"{"schemaVersion":1,"ownedStampIDs":["cat",{"id":"dog"}],"hasClearedOnce":true}"#.utf8)
        temporary.defaults.set(json, forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        var loaded = store.load()
        #expect(loaded.ownedStampIDs.isEmpty)
        #expect(loaded.hasClearedOnce)
        loaded.ownedStampIDs = ["rabbit"]
        store.save(loaded)
        #expect(store.unreadableBackups == [json])
    }

    /// 読めないデータが何度も来ても、前に退避したものを上書きしない（同じデータは 1 つだけ）
    @Test
    func backupsAccumulateWithoutDuplicates() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        let first = Data("壊れたデータ 1".utf8)
        let second = Data("壊れたデータ 2".utf8)
        temporary.defaults.set(first, forKey: UserDefaultsAppDataStore.defaultKey)
        _ = store.load()
        _ = store.load()
        temporary.defaults.set(second, forKey: UserDefaultsAppDataStore.defaultKey)
        _ = store.load()
        #expect(store.unreadableBackups == [first, second])
    }

    /// 読める保存データは退避しない
    @Test
    func readableDataIsNotBackedUp() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        store.save(sample)
        _ = store.load()
        #expect(store.unreadableBackups.isEmpty)
    }

    /// 新しい版のアプリが書いたデータは、読める項目だけ読み、元のデータも残す
    @Test
    func newerSchemaIsReadAndKept() throws {
        let temporary = try TemporaryDefaults()
        defer { temporary.removeSuite() }
        let json = #"{"schemaVersion":99,"hasClearedOnce":true,"somethingNew":[1,2]}"#
        temporary.defaults.set(Data(json.utf8), forKey: UserDefaultsAppDataStore.defaultKey)
        let store = UserDefaultsAppDataStore(defaults: temporary.defaults)
        #expect(store.load().hasClearedOnce)
        #expect(store.unreadableBackups == [Data(json.utf8)])
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
