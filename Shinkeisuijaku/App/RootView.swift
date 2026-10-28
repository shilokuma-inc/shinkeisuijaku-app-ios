//
//  RootView.swift
//  Shinkeisuijaku
//
//  アプリの一番外の画面。ホームを根にした `NavigationStack` に、プレイ（クリアのダイアログを含む）・スタンプちょう・おうちの方への画面を積む。
//  初回クリア前は、起動したときからプレイを積んでいるので、ホームを通らずにゲームが始まる。
//  保護者の確認のダイアログは、ホームからもクリアのダイアログからも出すので、`NavigationStack` 全体の上に重ねる。
//

import SwiftUI

/// アプリの一番外の画面
struct RootView: View {
    @State private var flow: AppFlow
    @Environment(\.scenePhase) private var scenePhase

    init(flow: AppFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        NavigationStack(path: $flow.path) {
            HomeView(
                resumeChoice: flow.resumeChoice,
                onPlay: flow.play,
                onChooseCourse: flow.chooseCourse,
                onOpenStampBook: flow.openStampBook,
                onOpenParents: flow.openParents
            )
            .toolbar(.hidden, for: .navigationBar)
            .courseSelectDialog(flow: flow)
            .navigationDestination(for: AppFlow.Destination.self) { destination in
                switch destination {
                case .game:
                    gameScreen
                case .stampBook:
                    stampBookScreen
                case .parents:
                    parentsScreen
                }
            }
        }
        .parentalGateDialog(flow: flow)
        .task {
            await flow.passStore.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // 前面に戻ったら、ほかの端末での購入・返金に合わせて権利を確かめ直す
                Task {
                    await flow.passStore.refreshEntitlement()
                }
            }
        }
    }

    /// プレイとクリアのダイアログ。戻るボタンとスワイプでは戻れない（「やめる」で確かめてからホームへ）
    @ViewBuilder private var gameScreen: some View {
        if let session = flow.session {
            GameScreen(
                session: session,
                hasPass: flow.hasPass,
                showsLockedGuide: flow.showsClearLockedGuide,
                haptics: flow.haptics,
                onQuit: flow.goHome,
                onCleared: flow.recordClear,
                onClearAction: flow.handle
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
        }
    }

    /// スタンプちょう。戻るのは「ホームにもどる」だけ（仕様書の遷移先はホーム。クリアから開いたときもホームへ）
    private var stampBookScreen: some View {
        StampBookView(layout: flow.stampBookLayout, onHome: flow.goHome)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
    }

    /// おうちの方への画面。戻るのは「ホームにもどる」だけ（仕様書の遷移先はホーム）。
    /// 鍵の付いた難易度から来ていれば、購入が終わったらそのゲームを始める
    private var parentsScreen: some View {
        ParentsView(passStore: flow.passStore, onHome: flow.goHome, onPurchased: flow.purchaseCompleted)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
    }
}

extension AppFlow {
    /// 起動のしかたに合わせた保存とストアで、画面の流れを作る（Unit テストのホスト・UI テスト・撮影モードではメモリ上の保存と擬似のストア）
    static func makeForLaunch() -> AppFlow {
        let store = AppDataStoreFactory.make()
        let passStore = PassStore(backend: PassStoreFactory.makeBackend(), dataStore: store)
        return AppFlow(store: store, passStore: passStore, haptics: SystemHaptics())
    }
}
