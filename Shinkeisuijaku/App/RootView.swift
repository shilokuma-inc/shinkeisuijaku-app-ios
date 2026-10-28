//
//  RootView.swift
//  Shinkeisuijaku
//
//  アプリの一番外の画面。ホームを根にした `NavigationStack` に、プレイ（クリアのダイアログを含む）を積む。
//  初回クリア前は、起動したときからプレイを積んでいるので、ホームを通らずにゲームが始まる。
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
                // コース選択のダイアログ（タスク 14）・スタンプちょう（タスク 15）・おうちの方へ（タスク 18）ができたらつなぐ
                onChooseCourse: { _ in },
                onOpenStampBook: {},
                onOpenParents: {}
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppFlow.Destination.self) { destination in
                switch destination {
                case .game:
                    gameScreen
                }
            }
        }
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
                haptics: flow.haptics,
                onQuit: flow.goHome,
                onCleared: flow.recordClear,
                onClearAction: flow.handle
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
        }
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
