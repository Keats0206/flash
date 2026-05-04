import SwiftUI

// MARK: - Confetti

struct CConfetti: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var burst = false

    var body: some View {
        ZStack {
            ForEach(0..<36, id: \.self) { i in
                confettiPiece(i)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: c.minHeight ?? 120)
        .clipped()
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) { burst = true }
        }
    }

    private func confettiPiece(_ i: Int) -> some View {
        let colors: [Color] = [palette.accent, palette.warning, palette.success, palette.danger, palette.accent.opacity(0.7)]
        let col = colors[i % colors.count]
        let x = CGFloat((i * 47) % 100) / 100.0 * 280 - 140
        let endY: CGFloat = burst ? 200 : -CGFloat(20 + (i % 7) * 10)
        return Rectangle()
            .fill(col)
            .frame(width: 7, height: 11)
            .rotationEffect(.degrees(Double(i * 19)))
            .offset(x: x, y: endY)
    }
}

// MARK: - Tooltip (popover)

struct CTooltip: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var show = false

    var body: some View {
        Button(action: { show.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: c.icon ?? "questionmark.circle")
                    .foregroundColor(palette.accent)
                Text(c.content ?? "Help")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(palette.accent)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $show, attachmentAnchor: .point(.top), arrowEdge: .top) {
            Text(c.subtitle ?? c.action ?? "Tip")
                .font(.subheadline)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Badge stack (overlapping avatars)

struct CBadgeStack: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var people: [LeafItem] { c.items ?? [] }

    var body: some View {
        HStack(spacing: -12) {
            ForEach(Array(people.prefix(5).enumerated()), id: \.offset) { i, item in
                ZStack {
                    Circle()
                        .stroke(Color.systemBg, lineWidth: 2)
                    Circle().fill(palette.accent.opacity(0.2 + Double(i) * 0.05))
                    Text(initials(item))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(palette.accent)
                }
                .frame(width: 32, height: 32)
            }
            if people.count > 5 {
                ZStack {
                    Circle().fill(palette.accent)
                    Text("+\(people.count - 5)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
            }
            if let cap = c.content {
                Text(cap).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func initials(_ item: LeafItem) -> String {
        if let e = item.emoji, !e.isEmpty { return String(e.prefix(1)) }
        return String(item.label.prefix(1)).uppercased()
    }
}

// MARK: - Story strip (IG-style pager)

struct CStory: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    private var slides: [LeafItem] { c.items ?? [] }

    var body: some View {
        if slides.isEmpty {
            Text("story needs items with mediaURL")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            TabView {
                ForEach(slides) { item in
                    ZStack(alignment: .bottomLeading) {
                        if let uStr = item.mediaURL ?? item.value,
                           let u = URL(string: uStr.contains("://") ? uStr : "https://\(uStr)") {
                            AsyncImage(url: u) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                default:
                                    Color.secondary.opacity(0.2)
                                }
                            }
                        } else {
                            Color.secondary.opacity(0.2)
                            if let e = item.emoji {
                                Text(e).font(.system(size: 64))
                            }
                        }
                        LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                            .frame(height: 100)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.label)
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                            if let sub = item.subtitle {
                                Text(sub)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: c.minHeight ?? 320)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: c.cornerRadius ?? 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: c.cornerRadius ?? 20)
                            .stroke(
                                LinearGradient(colors: [palette.accent, palette.accent.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 3
                            )
                    )
                }
            }
            .pageStyle()
            .frame(height: c.minHeight ?? 320)
        }
    }
}
