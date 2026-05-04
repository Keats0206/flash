import Foundation
import SwiftUI

/// Persists a coin balance; coins are spent when a new app is generated successfully.
@MainActor
final class CoinStore: ObservableObject {
    @Published private(set) var balance: Int

    /// Spent per successful `generateMicroApp` completion.
    static let buildCost = 10

    private static let defaultsKey = "coinBalance"
    private static let defaultStartingBalance = 50

    init() {
        let stored = UserDefaults.standard.object(forKey: Self.defaultsKey) as? Int
        if let stored {
            balance = max(0, stored)
        } else {
            balance = Self.defaultStartingBalance
            UserDefaults.standard.set(balance, forKey: Self.defaultsKey)
        }
    }

    var canAffordBuild: Bool { balance >= Self.buildCost }

    func setBalance(_ value: Int) {
        balance = max(0, value)
        UserDefaults.standard.set(balance, forKey: Self.defaultsKey)
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        setBalance(balance + amount)
    }

    /// Returns false if the balance is too low (caller should have checked `canAffordBuild`).
    @discardableResult
    func spendForBuild() -> Bool {
        guard balance >= Self.buildCost else { return false }
        setBalance(balance - Self.buildCost)
        return true
    }
}
