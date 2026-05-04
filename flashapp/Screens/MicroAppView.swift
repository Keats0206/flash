import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MicroAppView: View {
    @State private var app: MicroApp
    let onUpdate: (MicroApp) -> Void
    /// Demos hide the AI patch bar — duplicate into your library to remix.
    let showsEditChrome: Bool

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var sharedInbox: SharedInboxStore

    @State private var showFriendPicker = false
    @State private var accentColor: Color = .blue
    @StateObject private var bindingStore = FlashBindingStore()
    @State private var editText = ""
    @State private var editPhotos: [PromptPickablePhoto] = []
    /// Non-nil while an edit is in flight; label describes the current step.
    @State private var patchProgress: String? = nil
    @State private var patchError: String? = nil
    /// Patched preview is local until the user taps Save (then Share appears again).
    @State private var hasUnsavedChanges = false

    private var skinPalette: SkinPalette { .appDefault(appAccentHex: app.accent) }

    init(app: MicroApp, showsEditChrome: Bool = true, onUpdate: @escaping (MicroApp) -> Void = { _ in }) {
        _app = State(initialValue: app)
        self.onUpdate = onUpdate
        self.showsEditChrome = showsEditChrome
    }

    var body: some View {
        ZStack {
            FlashPalette.microAppDetailChrome.ignoresSafeArea()
            LinearGradient(
                colors: [accentColor.opacity(0.18), Color.clear],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(app.body.enumerated()), id: \.offset) { _, component in
                        ComponentView(c: component)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FlashPalette.microAppCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.06), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
                    radius: colorScheme == .dark ? 6 : 14,
                    x: 0,
                    y: colorScheme == .dark ? 4 : 5
                )
                .animation(.spring(response: 0.45), value: app.body.count)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(app.title)
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
        .toolbarBackground(FlashPalette.microAppDetailChrome, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .toolbar {
            if !showsEditChrome || !hasUnsavedChanges {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Share link", systemImage: "link", action: shareJSON)
                        Button("Send to friend…", systemImage: "person.crop.circle.badge.plus") {
                            showFriendPicker = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
            }
            if showsEditChrome {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveToLibrary() }
                        .fontWeight(.semibold)
                        .disabled(!hasUnsavedChanges)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if showsEditChrome {
                    EditBar(
                        text: $editText,
                        photos: $editPhotos,
                        patchProgress: patchProgress,
                        patchError: patchError,
                        onSend: sendPatch
                    )
                }
                AccentColorBar(accentColor: $accentColor)
            }
        }
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(app: app, isPresented: $showFriendPicker)
                .environmentObject(sharedInbox)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            accentColor = Color(hex: app.accent)
        }
        .onChange(of: accentColor) { _, new in
            #if canImport(UIKit)
            let hex = new.toHex()
            app = MicroApp(id: app.id, title: app.title, icon: app.icon, accent: hex, body: app.body, prompt: app.prompt)
            hasUnsavedChanges = true
            #endif
        }
        .environment(\.skinPalette, skinPalette)
        .environmentObject(bindingStore)
    }

    func sendPatch() {
        let instruction = editText.trimmingCharacters(in: .whitespaces)
        let attachments = editPhotos.map(\.attachment)
        guard (!instruction.isEmpty || !attachments.isEmpty), patchProgress == nil else { return }
        editText = ""
        editPhotos = []
        patchError = nil
        patchProgress = "Preparing your edit…"

        Task {
            do {
                let updated = try await patchMicroApp(
                    current: app,
                    instruction: instruction,
                    imageContext: attachments
                , onProgress: { status in
                    await MainActor.run {
                        patchProgress = status
                    }
                })
                await MainActor.run {
                    withAnimation(.spring(response: 0.45)) {
                        app = updated
                        hasUnsavedChanges = true
                    }
                    patchProgress = nil
                }
            } catch {
                await MainActor.run {
                    patchProgress = nil
                    patchError = error.localizedDescription
                }
            }
        }
    }

    private func saveToLibrary() {
        guard hasUnsavedChanges else { return }
        onUpdate(app)
        hasUnsavedChanges = false
    }

    func shareJSON() {
        guard let url = app.flashShareURL() else { return }
        #if os(iOS)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            av.popoverPresentationController?.sourceView = window
            window.rootViewController?.present(av, animated: true)
        }
        #endif
    }
}

// MARK: - Accent color bar

private struct AccentColorBar: View {
    @Binding var accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
            Text("Color")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            ColorPicker("", selection: $accentColor, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? FlashPalette.surfaceDark : Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Edit Bar

struct EditBar: View {
    @Binding var text: String
    @Binding var photos: [PromptPickablePhoto]
    let patchProgress: String?
    let patchError: String?
    let onSend: () -> Void
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.skinPalette) private var palette

    private var canSendPatch: Bool {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasText || !photos.isEmpty
    }

    private var fieldBg: Color {
        colorScheme == .dark ? FlashPalette.surfaceDark : Color.secondary.opacity(0.14)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.12)

            if let err = patchError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(err).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.orange.opacity(0.06))
            }

            if patchProgress == nil {
                PromptPhotoAttachmentStrip(photos: $photos)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            HStack(alignment: .bottom, spacing: 10) {
                if let step = patchProgress {
                    ProgressView().tint(palette.accent)
                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                } else {
                    TextField("Edit this app…", text: $text, axis: .vertical)
                        .font(.body)
                        .lineLimit(2...6)
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { if canSendPatch { onSend() } }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(canSendPatch ? palette.accent : Color.secondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendPatch)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(colorScheme == .dark ? FlashPalette.surfaceDark : Color(UIColor.systemBackground))
    }
}
