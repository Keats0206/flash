import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Checklist

struct ChecklistView: View {
    let items: [LeafItem]
    @Environment(\.skinPalette) private var palette
    @State private var checked: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                Button(action: { toggle(item) }) {
                    HStack(spacing: 12) {
                        Image(systemName: checked.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(checked.contains(item.id) ? palette.success : uncheckedColor(item))
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .strikethrough(checked.contains(item.id), color: .secondary)
                                .foregroundColor(checked.contains(item.id) ? .secondary : .primary)
                                .font(.subheadline)
                            if let sub = item.subtitle {
                                Text(sub).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                if item.id != items.last?.id { Divider().padding(.leading, 42) }
            }
        }
    }

    func uncheckedColor(_ item: LeafItem) -> Color {
        switch item.color {
        case "accent":  return palette.accent
        case "success": return palette.success
        case "danger":  return palette.danger
        case "warning": return palette.warning
        default:        return Color.tertiaryFg
        }
    }

    func toggle(_ item: LeafItem) {
        if checked.contains(item.id) {
            checked.remove(item.id)
        } else {
            checked.insert(item.id)
        }
    }
}

// MARK: - Swipe

struct SwipeView: View {
    let items: [LeafItem]
    @Environment(\.skinPalette) private var palette
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isDismissing = false

    var remaining: [LeafItem] { Array(items.dropFirst(currentIndex)) }

    var body: some View {
        ZStack {
            if currentIndex >= items.count {
                VStack(spacing: 10) {
                    Text("🎉").font(.system(size: 40))
                    Text("All done!").font(.headline)
                    Button("Start over") { withAnimation(.spring()) { currentIndex = 0 } }
                        .font(.subheadline.weight(.medium)).foregroundColor(palette.accent)
                }
            } else {
                ForEach(Array(remaining.prefix(3).enumerated().reversed()), id: \.offset) { i, item in
                    if i == 0 {
                        SwipeCardView(item: item)
                            .offset(offset)
                            .rotationEffect(.degrees(rotation))
                            .overlay(swipeIndicator)
                            .gesture(dragGesture)
                    } else {
                        SwipeCardView(item: item)
                            .scaleEffect(1.0 - Double(i) * 0.05)
                            .offset(y: Double(i) * 12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                guard !isDismissing else { return }
                offset = v.translation
                rotation = Double(v.translation.width / 20)
            }
            .onEnded { v in
                guard !isDismissing else { return }
                if abs(v.translation.width) > 120 {
                    isDismissing = true
                    let dir: CGFloat = v.translation.width > 0 ? 1 : -1
                    withAnimation(.spring(response: 0.3)) {
                        offset = CGSize(width: dir * 600, height: v.translation.height * 0.5)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        currentIndex += 1; offset = .zero; rotation = 0; isDismissing = false
                    }
                } else {
                    withAnimation(.spring()) { offset = .zero; rotation = 0 }
                }
            }
    }

    @ViewBuilder var swipeIndicator: some View {
        let threshold: Double = 30
        let opacity = max(0, min(1, (abs(Double(offset.width)) - threshold) / 60))
        ZStack {
            if offset.width > threshold {
                keepLabel
                    .opacity(opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)
            }
            if offset.width < -threshold {
                skipLabel
                    .opacity(opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var keepLabel: some View {
        Text("KEEP")
            .font(.caption.weight(.black))
            .foregroundColor(palette.success)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.success, lineWidth: 2.5))
            .rotationEffect(.degrees(-15))
    }

    var skipLabel: some View {
        Text("SKIP")
            .font(.caption.weight(.black))
            .foregroundColor(palette.danger)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.danger, lineWidth: 2.5))
            .rotationEffect(.degrees(15))
    }
}

struct SwipeCardView: View {
    let item: LeafItem
    var body: some View {
        VStack(spacing: 14) {
            if let e = item.emoji { Text(e).font(.system(size: 52)) }
            Text(item.label).font(.title3.weight(.bold)).multilineTextAlignment(.center)
            if let sub = item.subtitle {
                Text(sub).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24).padding(.vertical, 28)
        .background(Color.systemBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Pager

struct PagerView: View {
    let items: [LeafItem]
    @Environment(\.skinPalette) private var palette

    var body: some View {
        TabView {
            ForEach(items) { item in
                VStack(spacing: 14) {
                    if let e = item.emoji { Text(e).font(.system(size: 52)) }
                    Text(item.label)
                        .font(.title3.weight(.bold)).multilineTextAlignment(.center)
                    if let sub = item.subtitle {
                        Text(sub).font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
            }
        }
        .pageStyle()
        .frame(height: 230)
        .onAppear {
            #if os(iOS)
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(palette.accent)
            UIPageControl.appearance().pageIndicatorTintColor = UIColor(palette.accent).withAlphaComponent(0.3)
            #endif
        }
    }
}

// MARK: - Toggle

struct ToggleView: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @EnvironmentObject private var bindingStore: FlashBindingStore
    @State private var isOn: Bool

    init(c: Component) {
        self.c = c
        _isOn = State(initialValue: (c.value ?? 0) >= 1.0)
    }

    var body: some View {
        Toggle(c.content ?? "", isOn: toggleBinding)
            .font(.subheadline)
            .tint(palette.accent)
    }

    private var toggleBinding: Binding<Bool> {
        guard let key = c.name, !key.isEmpty else { return $isOn }
        return bindingStore.boolBinding(for: key, default: isOn)
    }
}

// MARK: - Stepper

struct StepperView: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @EnvironmentObject private var bindingStore: FlashBindingStore
    @State private var count: Int

    init(c: Component) {
        self.c = c
        _count = State(initialValue: Int(c.value ?? 0))
    }

    var body: some View {
        HStack {
            Text(c.content ?? "").font(.subheadline)
            Spacer()
            HStack(spacing: 16) {
                Button(action: {
                    if currentCount > 0 { countBinding.wrappedValue = Double(currentCount - 1) }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(currentCount > 0 ? palette.accent : Color.secondary.opacity(0.4))
                }
                .disabled(currentCount <= 0)
                Text("\(currentCount)").font(.title3.weight(.bold)).frame(minWidth: 28)
                Button(action: { countBinding.wrappedValue = Double(currentCount + 1) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(palette.accent)
                }
            }
        }
    }

    private var countBinding: Binding<Double> {
        guard let key = c.name, !key.isEmpty else {
            return Binding(get: { Double(count) }, set: { count = Int($0) })
        }
        return bindingStore.numberBinding(for: key, default: Double(count))
    }

    private var currentCount: Int {
        Int(countBinding.wrappedValue)
    }
}

// MARK: - Input

struct InputView: View {
    let c: Component
    @EnvironmentObject private var bindingStore: FlashBindingStore
    @State private var text = ""

    var body: some View {
        HStack(spacing: 10) {
            if let icon = c.icon {
                Image(systemName: icon).foregroundColor(.secondary).frame(width: 20)
            }
            TextField(c.content ?? "Enter text", text: textBinding)
                .font(.subheadline)
        }
        .padding(12)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .cornerRadius(c.style == "pill" ? 999 : 10)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        switch c.style {
        case "glass":
            Color.systemBg.opacity(0.65)
        case "outline":
            Color.clear
        case "poster":
            Color.secondaryBg.opacity(0.55)
        default:
            Color.secondaryBg
        }
    }

    @ViewBuilder
    private var fieldBorder: some View {
        if c.style == "outline" || c.style == "poster" {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private var textBinding: Binding<String> {
        guard let key = c.name, !key.isEmpty else { return $text }
        return bindingStore.stringBinding(for: key, default: text)
    }
}

// MARK: - Bound Input (for use inside AiQueryView)

struct BoundInputView: View {
    let c: Component
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            if let icon = c.icon {
                Image(systemName: icon).foregroundColor(.secondary).frame(width: 20)
            }
            TextField(c.content ?? "Enter text", text: $text)
                .font(.subheadline)
        }
        .padding(12)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .cornerRadius(c.style == "pill" ? 999 : 10)
    }

    @ViewBuilder
    private var fieldBackground: some View {
        switch c.style {
        case "glass":
            Color.systemBg.opacity(0.65)
        case "outline":
            Color.clear
        case "poster":
            Color.secondaryBg.opacity(0.55)
        default:
            Color.secondaryBg
        }
    }

    @ViewBuilder
    private var fieldBorder: some View {
        if c.style == "outline" || c.style == "poster" {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }
}

// MARK: - AI Query

struct AiQueryView: View {
    let c: Component
    @Environment(\.skinPalette) private var palette

    @State private var inputValues: [String: String] = [:]
    @State private var isLoading = false
    @State private var resultComponents: [Component] = []
    @State private var errorMessage: String? = nil

    private var buttonLabel: String { c.content ?? "Generate" }
    private var promptTemplate: String { c.action ?? "" }
    /// `"replace"` (default): each run replaces output. `"append"`: new blocks stack below previous runs.
    private var outputMode: String { (c.mode ?? "replace").lowercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array((c.children ?? []).enumerated()), id: \.offset) { index, child in
                if child.type == "input" {
                    let key = child.name ?? "input_\(index)"
                    BoundInputView(c: child, text: bindingFor(key: key))
                } else {
                    ComponentView(c: child)
                }
            }

            Button(action: fireQuery) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isLoading ? "Thinking…" : buttonLabel)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isLoading ? palette.accent.opacity(0.6) : palette.accent)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .animation(.easeInOut(duration: 0.2), value: isLoading)

            if let err = errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange).font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Couldn't get a response")
                            .font(.subheadline.weight(.semibold))
                        Text(err).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !resultComponents.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(resultComponents.enumerated()), id: \.offset) { _, comp in
                        ComponentView(c: comp)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: resultComponents.count)
        .animation(.spring(response: 0.35), value: errorMessage)
    }

    private func bindingFor(key: String) -> Binding<String> {
        Binding(
            get: { inputValues[key] ?? "" },
            set: { inputValues[key] = $0 }
        )
    }

    private func interpolate(_ template: String) -> String {
        var result = template
        for (key, value) in inputValues {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }

    private func fireQuery() {
        let prompt = interpolate(promptTemplate).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            errorMessage = "Fill in the fields first"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                let components = try await queryComponents(prompt: prompt)
                await MainActor.run {
                    withAnimation(.spring(response: 0.45)) {
                        if outputMode == "append" {
                            resultComponents.append(contentsOf: components)
                        } else {
                            resultComponents = components
                        }
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Tag Cloud

struct TagCloudView: View {
    let c: Component
    @Environment(\.skinPalette) private var palette
    @State private var selected: Set<String> = []
    var items: [LeafItem] { c.items ?? [] }

    func tagColor(_ item: LeafItem) -> Color {
        switch item.color {
        case "accent":    return palette.accent
        case "success":   return palette.success
        case "danger":    return palette.danger
        case "warning":   return palette.warning
        case "secondary": return .secondary
        default:          return c.resolvedColor(palette: palette)
        }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: c.spacing ?? 8) {
            ForEach(items) { item in
                let color = tagColor(item)
                let isSelected = selected.contains(item.id)
                Button(action: {
                    if isSelected { selected.remove(item.id) } else { selected.insert(item.id) }
                }) {
                    Text(item.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(isSelected ? color : color.opacity(0.12))
                        .foregroundColor(isSelected ? .white : color)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25), value: isSelected)
            }
        }
    }
}
