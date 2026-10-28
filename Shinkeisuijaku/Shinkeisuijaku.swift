//
//  Shinkeisuijaku.swift
//  Shinkeisuijaku
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftUI

@main
struct Shinkeisuijaku: App {
    /// 画面の流れ。`body` が評価し直されても作り直さないよう、起動したときに 1 回だけ作る（撮影モードでは使わない）
    private let flow: AppFlow?

    init() {
        flow = ScreenshotDemo.scene == nil ? AppFlow.makeForLaunch() : nil
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    /// 撮影モード（ScreenshotDemo）のときは、撮る画面を開く
    @ViewBuilder private var rootView: some View {
        switch ScreenshotDemo.scene {
        case nil:
            if let flow {
                RootView(flow: flow)
            }
        case .home:
            HomeScreenshotDemoView()
        case .designTokenColors:
            DesignTokenCatalogView(page: .colors)
        case .designTokenTypes:
            DesignTokenCatalogView(page: .typeAndMetrics)
        case .illustrations:
            IllustrationCatalogView()
        case .cards:
            CardCatalogView()
        case .stamps:
            StampCatalogView()
        case .play:
            PlayScreenshotDemoView()
        case .clear:
            ClearScreenshotDemoView()
        case .parentalGate:
            ParentalGateScreenshotDemoView()
        }
    }
}
