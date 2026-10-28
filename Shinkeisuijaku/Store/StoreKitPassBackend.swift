//
//  StoreKitPassBackend.swift
//  Shinkeisuijaku
//
//  StoreKit 2 で「ぜんぶ遊べるパス」を扱う。開発とテストでは、スキームの StoreKit Configuration ファイル（`Configs/Shinkeisuijaku.storekit`）が使われる。
//

import Foundation
import StoreKit

/// StoreKit 2 のストア
@MainActor
final class StoreKitPassBackend: PassStoreBackend {
    private var product: Product?

    func loadDisplayPrice() async -> String? {
        await loadProduct()?.displayPrice
    }

    func purchase() async -> PassPurchaseResult {
        guard let product = await loadProduct() else {
            return .failed
        }
        do {
            switch try await product.purchase() {
            case let .success(verification):
                guard case let .verified(transaction) = verification else {
                    // 検証に失敗した取引は権利にしない（取引は終わらせず、App Store に任せる）
                    return .unverified
                }
                await transaction.finish()
                return transaction.revocationDate == nil ? .purchased : .failed
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func hasEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               transaction.productID == PassProduct.id,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    func sync() async -> Bool {
        do {
            try await AppStore.sync()
            return true
        } catch {
            return false
        }
    }

    func transactionUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    if case let .verified(transaction) = result {
                        await transaction.finish()
                    }
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// パスの商品を読む（一度読めたら持っておく）
    private func loadProduct() async -> Product? {
        if let product {
            return product
        }
        let loaded = try? await Product.products(for: [PassProduct.id]).first
        product = loaded
        return loaded
    }
}
