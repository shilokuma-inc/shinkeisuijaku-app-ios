//
//  Shinkeisuijaku.swift
//  Shinkeisuijaku
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftUI

@main
struct Shinkeisuijaku: App {
    /// 保存とストア。窓がいくつ開いても 1 つを共有するよう、起動したときに 1 回だけ作る（撮影モードでは使わない）。
    /// 画面の流れ（`AppFlow`）は窓ごとに `RootView` が作る
    private let services: AppServices?

    init() {
        services = ScreenshotDemo.scene == nil ? AppServices.makeForLaunch() : nil
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
            if let services {
                RootView(services: services)
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
        case .courseSelect:
            CourseSelectScreenshotDemoView()
        case .stampBook:
            StampBookScreenshotDemoView()
        case .stampBookBeforePass:
            StampBookScreenshotDemoView(hasPass: false)
        case .parents:
            ParentsScreenshotDemoView()
        }
    }
}
