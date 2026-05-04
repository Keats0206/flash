import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Section

struct CSection: View {
    let c: Component

    var body: some View {
        VStack(alignment: c.resolvedHAlign, spacing: c.spacing ?? 10) {
            if let title = c.content, !title.isEmpty {
                Text(title)
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: alignmentFromH(c.resolvedHAlign))
            }
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                ComponentView(c: child)
            }
        }
        .frame(maxWidth: .infinity, alignment: .init(horizontal: c.resolvedHAlign, vertical: .center))
    }

    private func alignmentFromH(_ h: HorizontalAlignment) -> Alignment {
        switch h {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}

// MARK: - List

struct CList: View {
    let c: Component

    var body: some View {
        List {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                ComponentView(c: child)
                    .listRowInsets(EdgeInsets(
                        top: 4,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    ))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .frame(minHeight: c.minHeight.map { CGFloat($0) })
    }
}

// MARK: - Tabs (items = labels, children[i] = pane)

struct CTabs: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    @State private var selectedIndex = 0

    private var labels: [String] {
        let fromItems = (c.items ?? []).map(\.label)
        if !fromItems.isEmpty { return fromItems }
        let n = max(panes.count, 1)
        return (0..<n).map { "Tab \($0 + 1)" }
    }
    private var panes: [Component] { c.kids }

    private var tabCount: Int { max(labels.count, panes.count, 1) }

    var body: some View {
        if c.kids.isEmpty && (c.items ?? []).isEmpty {
            Text("Tabs need items (labels) and children (panes)")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Picker("", selection: Binding(
                    get: { min(selectedIndex, max(0, tabCount - 1)) },
                    set: { selectedIndex = $0 }
                )) {
                    ForEach(0..<tabCount, id: \.self) { i in
                        Text(i < labels.count ? labels[i] : "Tab \(i + 1)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .tint(palette.accent)

                Group {
                    if selectedIndex < panes.count {
                        ComponentView(c: panes[selectedIndex])
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(c.padding ?? 8)
            .background(c.resolvedBg(palette: palette))
            .cornerRadius(c.cornerRadius ?? 12)
        }
    }
}

// MARK: - Accordion

struct CAccordion: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                DisclosureGroup {
                    if child.kids.isEmpty {
                        Text(child.subtitle ?? " ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(child.kids.enumerated()), id: \.offset) { _, grand in
                            ComponentView(c: grand)
                        }
                    }
                } label: {
                    Text(accordionTitle(for: child))
                        .font(.subheadline.weight(.semibold))
                }
                .tint(palette.accent)
            }
        }
        .padding(c.padding ?? 8)
    }

    private func accordionTitle(for child: Component) -> String {
        if child.type == "section", let t = child.content, !t.isEmpty { return t }
        return child.content ?? child.type
    }
}

// MARK: - Sheet

struct CSheet: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var open = false

    var body: some View {
        Button(action: { open = true }) {
            HStack {
                if let icon = c.icon { Image(systemName: icon) }
                Text(c.content ?? "Open")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(palette.accent.opacity(0.12))
            .foregroundColor(palette.accent)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $open) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                            ComponentView(c: child)
                        }
                    }
                    .padding()
                }
                .navigationTitle(c.subtitle ?? "")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { open = false }
                    }
                }
            }
        }
    }
}

// MARK: - Modal (full screen)

struct CModal: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var open = false

    var body: some View {
        Button(action: { open = true }) {
            HStack {
                if let icon = c.icon { Image(systemName: icon) }
                Text(c.content ?? "Present")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(14)
            .background(c.resolvedBg(palette: palette))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .fullScreenCover(isPresented: $open) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                            ComponentView(c: child)
                        }
                    }
                    .padding()
                }
                .navigationTitle(c.subtitle ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { open = false }
                    }
                }
            }
        }
        #else
        .sheet(isPresented: $open) {
            VStack {
                ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                    ComponentView(c: child)
                }
            }
            .padding()
        }
        #endif
    }
}

// MARK: - Nav (horizontal chips)

struct CNav: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(c.items ?? [], id: \.id) { item in
                    Button(action: {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }) {
                        HStack(spacing: 6) {
                            if let icon = item.icon {
                                Image(systemName: icon).font(.caption)
                            }
                            Text(item.label)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(palette.accent.opacity(0.15))
                        .foregroundColor(palette.accent)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
