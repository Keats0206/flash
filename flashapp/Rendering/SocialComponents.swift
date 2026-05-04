import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Comment

struct CComment: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            profileGlyph(size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(c.content ?? "")
                    .font(.subheadline.weight(.semibold))
                if let sub = c.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func profileGlyph(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(palette.accent.opacity(0.2))
            if let icon = c.icon {
                Image(systemName: icon)
                    .foregroundColor(palette.accent)
            } else {
                Text(String((c.content ?? "?").prefix(1)).uppercased())
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(palette.accent)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Thread (nested children)

struct CThread: View {
    let c: Component

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { depth, child in
                CThreadNode(c: child, depth: depth)
            }
        }
        .padding(.leading, 4)
    }
}

private struct CThreadNode: View {
    let c: Component
    let depth: Int
    @Environment(\.skinPalette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(palette.accent.opacity(0.35))
                .frame(width: 3)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(c.content ?? "")
                        .font(.subheadline.weight(.semibold))
                    if let sub = c.subtitle {
                        Text(sub)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                if let t = c.items?.first?.label {
                    Text(t)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ForEach(Array(c.kids.enumerated()), id: \.offset) { _, sub in
                    CThreadNode(c: sub, depth: depth + 1)
                }
            }
        }
        .padding(.leading, CGFloat(depth) * 8)
    }
}

// MARK: - Reaction bar

struct CReactionBar: View {
    let c: Component

    private var reactions: [String] {
        if let items = c.items, !items.isEmpty {
            return items.map { $0.emoji ?? $0.label }
        }
        return ["👍", "❤️", "🔥", "😂"]
    }

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(reactions.enumerated()), id: \.offset) { _, r in
                Button(action: {}) {
                    Text(r)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - Share

struct CShare: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        Button(action: {
            if c.action != nil {
                FlashActionRuntime.perform(from: c, fallbackText: c.content)
            } else {
                presentShare()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: c.icon ?? "square.and.arrow.up")
                Text(c.content ?? "Share")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(palette.accent)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(palette.accent.opacity(0.12))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    private func presentShare() {
        #if os(iOS)
        var items: [Any] = []
        if let t = c.content { items.append(t) }
        if let u = flashShareURL(from: c.src) { items.append(u) }
        guard !items.isEmpty else { return }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            av.popoverPresentationController?.sourceView = window
            window.rootViewController?.present(av, animated: true)
        }
        #endif
    }

    private func flashShareURL(from string: String?) -> URL? {
        guard var s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if !s.contains("://") { s = "https://" + s }
        return URL(string: s)
    }
}

// MARK: - Vote

struct CVote: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var up = 0
    @State private var down = 0

    var body: some View {
        HStack(spacing: 20) {
            Button(action: { up += 1 }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("\(up)")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
            Button(action: { down += 1 }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("\(down)")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            if let t = c.content {
                Text(t).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Poll

struct CPoll: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var selected: String?

    private var options: [LeafItem] { c.items ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let t = c.content {
                Text(t).font(.subheadline.weight(.bold))
            }
            ForEach(options) { item in
                Button(action: { selected = item.id }) {
                    HStack {
                        Image(systemName: selected == item.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selected == item.id ? palette.accent : .secondary)
                        Text(item.label).font(.subheadline)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(c.padding ?? 8)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 12)
    }
}

// MARK: - Profile

struct CProfile: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        VStack(spacing: 14) {
            if let u = profileImageURL(from: c.src) ?? profileImageURL(from: c.content) {
                AsyncImage(url: u) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color.secondary.opacity(0.15)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(Circle().stroke(palette.accent.opacity(0.4), lineWidth: 2))
            } else {
                ZStack {
                    Circle().fill(palette.accent.opacity(0.2))
                    if let icon = c.icon {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundColor(palette.accent)
                    } else if let name = c.content {
                        Text(initials(from: name))
                            .font(.title2.weight(.bold))
                            .foregroundColor(palette.accent)
                    }
                }
                .frame(width: 88, height: 88)
            }

            Text(c.content ?? "")
                .font(.title3.weight(.bold))
            if let sub = c.subtitle {
                Text(sub)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !c.kids.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                        ComponentView(c: child)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(c.padding ?? 16)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 16)
    }

    private func profileImageURL(from string: String?) -> URL? {
        guard var s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if !s.contains("://") { s = "https://" + s }
        return URL(string: s)
    }

    private func initials(from name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }
}

// MARK: - Presence

struct CPresence: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill((c.value ?? 1) >= 1 ? palette.success : Color.secondary)
                .frame(width: 10, height: 10)
            Text(c.content ?? "")
                .font(.caption.weight(.medium))
            if let sub = c.subtitle {
                Text("· \(sub)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
