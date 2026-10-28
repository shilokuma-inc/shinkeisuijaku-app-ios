# LEARNINGS — shinkeisuijaku-app-ios の知見

このリポジトリだけで通じる知見を溜める（全リポジトリ共通の知見は `~/.agents/LEARNINGS.md`）。

- 1 項目 = 1 つの箇条書き。見出しの下に追記し、日付（YYYY-MM-DD）を添える
- コードや git の履歴を読めば分かることは書かない。PC 固有の値（ローカルパス・Simulator の UDID）と秘密情報は書かない
- 古くなった項目は消すか直す

## ビルド・テスト

## SwiftUI・デザイン

## StoreKit・保存

- Xcode 26.6 / iOS 26.5 の Simulator で、Unit テスト（Swift Testing・アプリがホスト）から `SKTestSession(contentsOf:)` と `SKTestSession(configurationFileNamed:)` のどちらで `Configs/Shinkeisuijaku.storekit` を開いても、`storefront` が空のまま `Product.products(for:)` が 0 件を返した（ファイルは読めている。原因は特定できていない）。StoreKit の判定は `PassStoreBackend` の擬似の実装で Unit テストし、StoreKit そのものは Xcode の Run（スキームの StoreKit Configuration）と実機で確かめる（2026-10-28）

## App Store の掲載
