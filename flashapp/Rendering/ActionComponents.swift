import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CTA (primary call-to-action)

struct CCTA: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        Button(action: { FlashActionRuntime.perform(from: c, fallbackText: c.content) }) {
            HStack(spacing: 10) {
                if let icon = c.icon { Image(systemName: icon) }
                Text(c.content ?? "Get started")
                    .font(.title3.weight(.bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [palette.accent, palette.accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(c.cornerRadius ?? 16)
            .shadow(color: palette.accent.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAB

struct CFloatingButton: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        HStack {
            Spacer()
            Button(action: { FlashActionRuntime.perform(from: c, fallbackText: c.subtitle ?? c.content) }) {
                Image(systemName: c.icon ?? "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(palette.accent)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Timer

struct CTimer: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var anchor = Date()

    private var total: TimeInterval {
        let d = c.duration ?? c.value ?? 60
        return max(1, d)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let elapsed = context.date.timeIntervalSince(anchor)
            let remaining = max(0, total - elapsed)
            let m = Int(remaining) / 60
            let s = Int(remaining) % 60
            VStack(spacing: 8) {
                Text(c.content ?? "Timer")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(String(format: "%02d:%02d", m, s))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(palette.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(c.padding ?? 16)
            .background(c.resolvedBg(palette: palette))
            .cornerRadius(c.cornerRadius ?? 14)
        }
    }
}

// MARK: - Counter

struct CCounter: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var n: Int

    init(c: Component) {
        self.c = c
        _n = State(initialValue: Int(c.value ?? 0))
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(c.content ?? "Count").font(.subheadline.weight(.medium))
            Spacer()
            Button(action: { n -= 1 }) {
                Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
            Text("\(n)").font(.title2.weight(.bold)).monospacedDigit().frame(minWidth: 36)
            Button(action: { n += 1 }) {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(c.padding ?? 12)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 12)
    }
}

// MARK: - Progress ring

struct CProgressRing: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var animated = false

    private var progress: CGFloat { CGFloat(min(1, max(0, c.value ?? 0))) }

    var body: some View {
        let size = CGFloat(c.minHeight ?? 100)
        ZStack {
            Circle()
                .stroke(palette.accent.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: animated ? progress : 0)
                .stroke(palette.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8), value: animated)
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title2.weight(.bold))
                if let t = c.content {
                    Text(t).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { animated = true }
    }
}

// MARK: - Form

struct CForm: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    var body: some View {
        Form {
            Section {
                ForEach(Array(c.kids.enumerated()), id: \.offset) { _, child in
                    ComponentView(c: child)
                }
            }
        }
        .frame(minHeight: c.minHeight ?? 200)
        .scrollContentBackground(.hidden)
        .background(c.resolvedBg(palette: palette))
        .cornerRadius(c.cornerRadius ?? 12)
    }
}

// MARK: - Select (picker)

struct CSelect: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @EnvironmentObject private var bindingStore: FlashBindingStore
    private var options: [LeafItem] { c.items ?? [] }

    @State private var pick: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let t = c.content {
                Text(t).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            Picker("", selection: selectionBinding) {
                Text("Choose…").tag("")
                ForEach(options) { item in
                    Text(item.label).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .tint(palette.accent)
        }
        .padding(12)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .cornerRadius(c.style == "pill" ? 999 : 10)
        .onAppear {
            if selectionBinding.wrappedValue.isEmpty, let f = options.first?.id {
                selectionBinding.wrappedValue = f
            }
        }
    }

    private var selectionBinding: Binding<String> {
        guard let key = c.name, !key.isEmpty else { return $pick }
        return bindingStore.stringBinding(for: key, default: pick)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        switch c.style {
        case "outline":
            Color.clear
        case "glass":
            Color.systemBg.opacity(0.65)
        default:
            Color.secondaryBg
        }
    }

    @ViewBuilder
    private var fieldBorder: some View {
        if c.style == "outline" {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(palette.accent.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Date picker field

struct CDatePicker: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @EnvironmentObject private var bindingStore: FlashBindingStore
    @State private var date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let t = c.content {
                Text(t).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            DatePicker("", selection: dateBinding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(palette.accent)
        }
        .padding(12)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .cornerRadius(c.style == "pill" ? 999 : 10)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        switch c.style {
        case "outline":
            Color.clear
        case "glass":
            Color.systemBg.opacity(0.65)
        default:
            Color.secondaryBg
        }
    }

    @ViewBuilder
    private var fieldBorder: some View {
        if c.style == "outline" {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(palette.accent.opacity(0.2), lineWidth: 1)
        }
    }

    private var dateBinding: Binding<Date> {
        guard let key = c.name, !key.isEmpty else { return $date }
        return bindingStore.dateBinding(for: key, default: date)
    }
}

// MARK: - Upload (document picker)

struct CUpload: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var importer = false
    @State private var name: String?

    var body: some View {
        Button(action: { importer = true }) {
            HStack(spacing: 10) {
                Image(systemName: c.icon ?? "arrow.up.doc")
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.content ?? "Upload file").font(.subheadline.weight(.semibold))
                    if let n = name {
                        Text(n).font(.caption).foregroundColor(.secondary)
                    } else if let sub = c.subtitle {
                        Text(sub).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(palette.accent.opacity(0.1))
            .foregroundColor(palette.accent)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .fileImporter(isPresented: $importer, allowedContentTypes: [.item, .image, .data]) { result in
            switch result {
            case .success(let url):
                name = url.lastPathComponent
            case .failure:
                break
            }
        }
    }
}
