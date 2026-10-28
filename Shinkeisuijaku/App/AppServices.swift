//
//  AppServices.swift
//  Shinkeisuijaku
//
//  アプリで 1 つだけ持つもの（端末内の保存・パスのストア・振動）。画面の流れ（`AppFlow`）は窓ごとに作り、これを共有する。
//  iPad で窓が 2 つ開いても、ゲーム・クリアの記録・積んだ画面は窓ごとに分かれ、保存とパスの権利だけが共通になる
//  （1 回のクリアで 2 つのスタンプが入らない・片方の窓を閉じてももう片方のゲームが止まらない）。
//

import Foundation

/// アプリで 1 つだけ持つもの
@MainActor
final class AppServices {
    /// 端末内の保存（スタンプ・購入状態のキャッシュ・前回のコースと難易度・初回クリア済みか）
    let store: any AppDataStore
    /// パスのストア（取引の変化の購読はアプリの寿命で続ける）
    let passStore: PassStore
    let haptics: any Haptics

    init(store: any AppDataStore, passStore: PassStore, haptics: any Haptics) {
        self.store = store
        self.passStore = passStore
        self.haptics = haptics
    }

    /// 起動のしかたに合わせた保存とストアを作る（Unit テストのホスト・UI テスト・撮影モードではメモリ上の保存と擬似のストア）
    static func makeForLaunch() -> AppServices {
        if let launch = UITestingLaunch.current {
            return launch.makeServices()
        }
        let store = AppDataStoreFactory.make()
        let passStore = PassStore(backend: PassStoreFactory.makeBackend(), dataStore: store)
        return AppServices(store: store, passStore: passStore, haptics: SystemHaptics())
    }
}
