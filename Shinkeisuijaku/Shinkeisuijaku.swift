//
//  Shinkeisuijaku.swift
//  Shinkeisuijaku
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftUI

@main
struct Shinkeisuijaku: App {
    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    /// 撮影モード（ScreenshotDemo）のときは、撮る画面を開く
    @ViewBuilder private var rootView: some View {
        switch ScreenshotDemo.scene {
        case .home, nil:
            ContentView()
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
        }
    }
}
