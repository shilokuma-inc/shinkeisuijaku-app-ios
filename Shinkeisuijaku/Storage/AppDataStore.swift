//
//  AppDataStore.swift
//  Shinkeisuijaku
//
//  端末内の保存の入れ物。アプリでは `UserDefaults`、テスト・UI テスト・撮影モードではメモリ上の実装を使う
//  （実際の `UserDefaults` を汚さないため）。
//

import Foundation

/// 端末内のデータを読み書きするもの
@MainActor
protocol AppDataStore: AnyObject {
    /// 保存したデータを読む。無い・読めないときは既定値を返す（クラッシュしない）
    func load() -> AppData
    /// データを保存する
    func save(_ data: AppData)
}

/// `UserDefaults` に JSON で保存する
final class UserDefaultsAppDataStore: AppDataStore {
    /// 保存に使うキー
    static let defaultKey = "appData"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = UserDefaultsAppDataStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    /// 読めなかったデータを残しておくキー。既定値で起動して上書きしても、元のデータを捨てないため
    var unreadableBackupKey: String {
        "\(key).unreadable"
    }

    func load() -> AppData {
        guard let data = defaults.data(forKey: key) else {
            return .initial
        }
        // 新しい版のアプリが書いたデータは読める項目だけ読み、元のデータも残しておく（古い版に戻しても失わないため）
        if let version = AppData.schemaVersion(of: data), version > AppData.currentSchemaVersion {
            defaults.set(data, forKey: unreadableBackupKey)
        }
        do {
            return try JSONDecoder().decode(AppData.self, from: data)
        } catch {
            defaults.set(data, forKey: unreadableBackupKey)
            return .initial
        }
    }

    func save(_ data: AppData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        defaults.set(encoded, forKey: key)
    }
}

/// メモリ上だけに保存する（テスト・UI テスト・撮影モード用。アプリを終了すると消える）
final class InMemoryAppDataStore: AppDataStore {
    private(set) var data: AppData
    /// 保存した回数（テストで、保存したかを確かめるため）
    private(set) var saveCount = 0

    init(data: AppData = .initial) {
        self.data = data
    }

    func load() -> AppData {
        data
    }

    func save(_ data: AppData) {
        self.data = data
        saveCount += 1
    }
}

/// 起動のしかたに合わせて保存の入れ物を選ぶ
enum AppDataStoreFactory {
    /// UI テストで起動したときの起動引数
    static let uiTestingArgument = "-uiTesting"

    /// Unit テストのホスト・UI テスト・撮影モードではメモリ上、それ以外は `UserDefaults`
    static func make(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> any AppDataStore {
        let isUnitTestHost = environment["XCTestConfigurationFilePath"] != nil
        let isUITesting = arguments.contains(uiTestingArgument)
        let isScreenshotDemo = arguments.contains("-screenshot-demo")
        if isUnitTestHost || isUITesting || isScreenshotDemo {
            return InMemoryAppDataStore()
        }
        return UserDefaultsAppDataStore()
    }
}
