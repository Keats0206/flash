import SwiftUI

struct CoinPack: Identifiable {
    let title: String
    let coins: Int
    let price: String
    let isPopular: Bool

    var id: String { title }
}

struct CoinsView: View {
    @EnvironmentObject private var coinStore: CoinStore

    private let packs: [CoinPack] = [
        CoinPack(title: "Starter", coins: 100, price: "$0.99", isPopular: false),
        CoinPack(title: "Value", coins: 500, price: "$3.99", isPopular: true),
        CoinPack(title: "Pro", coins: 1_200, price: "$7.99", isPopular: false),
        CoinPack(title: "Studio", coins: 3_000, price: "$14.99", isPopular: false),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title)
                            .foregroundStyle(FlashPalette.blue)
                        Text("\(coinStore.balance)")
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .contentTransition(.numericText())
                    }
                    Text("Each new app you generate uses \(CoinStore.buildCost) coins.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.secondaryBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Get more coins")
                        .font(.headline)
                    Text("Top up to keep building micro-apps with AI.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(packs) { pack in
                        packRow(pack)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FlashPalette.canvasLight.ignoresSafeArea(edges: .bottom))
        #if os(iOS)
        .navigationTitle("Coins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlashPalette.canvasLight, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    private func packRow(_ pack: CoinPack) -> some View {
        Button {
            coinStore.addCoins(pack.coins)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(pack.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        if pack.isPopular {
                            Text("Best value")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(FlashPalette.blue.opacity(0.15))
                                .foregroundStyle(FlashPalette.blue)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(pack.coins) coins")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                buyPill(price: pack.price)
            }
            .padding(16)
            .background(Color.systemBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PackPurchaseButtonStyle())
    }

    /// High-contrast pill so each pack reads as a purchasable control.
    private func buyPill(price: String) -> some View {
        HStack(spacing: 6) {
            Text("Buy")
                .font(.subheadline.weight(.semibold))
            Text(price)
                .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(FlashPalette.blue)
        .clipShape(Capsule())
        .accessibilityLabel("Buy for \(price)")
    }
}

/// Slight scale + opacity feedback so taps feel like real buttons.
private struct PackPurchaseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
struct CoinsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CoinsView()
        }
        .environmentObject(CoinStore())
    }
}
#endif
