//
//  UITestingLaunch.swift
//  Shinkeisuijaku
//
//  UI テスト（`ShinkeisuijakuUITests`）で起動したときの切り替え。起動引数の `-uiTesting` があるときだけ効く。
//  メモリ上の保存・擬似のストアに加えて、乱数の種を固定し（カードの配り方・スタンプ・保護者の確認の問題）、待ち時間を無くす
//  （全部見せる・ハズレ・ヒント・クリアまでの間。UI テストが固定時間で待たずに次の操作へ進めるようにする）。
//  ほかの起動引数（初期の保存・復元できる購入）は、`-uiTesting` が無ければ効かない（一般の利用者は起動引数を渡せないが、念のため）。
//
//  裏のカードの中身はアクセシビリティに出さない（VoiceOver で答えが分かってしまう）。UI テストはカードの識別子に付けた
//  ペアの番号で揃える組を見つける。番号を付けるのは `-uiTesting` のときだけで、通常の起動では位置の番号だけにする。
//

import Foundation

/// UI テストで起動したときの設定
struct UITestingLaunch: Equatable {
    /// UI テストで起動したことを示す起動引数（保存の入れ物・ストアの切り替えと同じ）
    static let argument = AppDataStoreFactory.uiTestingArgument
    /// 1 回クリアした後の保存で始める（ホームから始まる）
    static let clearedOnceArgument = "-uiTestingClearedOnce"
    /// 擬似のストアに、復元で戻るパスの購入を持たせる
    static let restorableArgument = "-uiTestingRestorable"
    /// 乱数の種（カードの配り方・スタンプ・保護者の確認の問題）。UI テストは並びを決め打ちにせず、カードの識別子のペアの番号を見る
    static let seed: UInt64 = 1

    /// 1 回クリアした後の保存で始めるか
    let startsClearedOnce: Bool
    /// 復元で戻るパスの購入があるか
    let hasRestorablePass: Bool

    /// 起動引数から読む。`-uiTesting` が無ければ nil（ほかの UI テスト用の引数があっても効かない）
    init?(arguments: [String]) {
        guard arguments.contains(Self.argument) else {
            return nil
        }
        startsClearedOnce = arguments.contains(Self.clearedOnceArgument)
        hasRestorablePass = arguments.contains(Self.restorableArgument)
    }

    /// 今の起動の設定（UI テストでなければ nil）
    static let current = UITestingLaunch(arguments: ProcessInfo.processInfo.arguments)

    /// 始めの保存
    var initialData: AppData {
        AppData(hasClearedOnce: startsClearedOnce)
    }

    /// アプリで 1 つの、メモリ上の保存と擬似のストア（始めの保存と、復元で戻る購入を持たせる）
    func makeServices() -> AppServices {
        let store = InMemoryAppDataStore(data: initialData)
        let backend = FakePassStoreBackend()
        backend.restorableEntitlement = hasRestorablePass
        return AppServices(store: store, passStore: PassStore(backend: backend, dataStore: store), haptics: SilentHaptics())
    }

    /// 窓ごとの画面の流れ。種を固定した乱数・待たない時計で作る
    func makeFlow(services: AppServices) -> AppFlow {
        AppFlow(
            store: services.store,
            passStore: services.passStore,
            haptics: services.haptics,
            timing: .uiTesting,
            clock: InstantGameClock(),
            generator: SeededRandomNumberGenerator(seed: Self.seed),
            parentalGateGenerator: SeededRandomNumberGenerator(seed: Self.seed)
        )
    }

    /// 保存とストアも新しく作って、画面の流れを作る（Unit テスト用）
    func makeFlow() -> AppFlow {
        makeFlow(services: makeServices())
    }

    /// プレイ画面のカードの識別子。通常は位置の番号だけ（`play.card.3`）、UI テストのときだけペアの番号も付ける（`play.card.3.pair.1`）
    /// - Parameter launch: UI テストの設定（通常の起動では nil）
    static func cardIdentifier(index: Int, pairID: Int, launch: UITestingLaunch? = current) -> String {
        guard launch != nil else {
            return "play.card.\(index)"
        }
        return "play.card.\(index).pair.\(pairID)"
    }
}
