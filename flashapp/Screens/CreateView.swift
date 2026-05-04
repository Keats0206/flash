import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Build (create) flow — pushed via navigation, chat bar at bottom

private enum BuildPhase: Equatable {
    case compose
    case generating
    case preview
}

struct CreateView: View {
    let onDismiss: () -> Void
    let onSave: (MicroApp) -> Void

    @EnvironmentObject private var coinStore: CoinStore

    @State private var phase: BuildPhase = .compose
    @State private var prompt = ""
    #if canImport(UIKit)
    @State private var contextPhotos: [PromptPickablePhoto] = []
    #endif
    @State private var locationContext: String? = nil
    @State private var calendarContext: String? = nil
    @State private var fetchingLocation = false
    @State private var fetchingCalendar = false
    /// Editable in preview before Save — may diverge from generated `draft.prompt`.
    @State private var draftPrompt = ""
    @State private var draftApp: MicroApp?
    @State private var errorMessage: String?

    @State private var finishedSteps: [String] = []
    @State private var liveStep = ""
    @State private var revealedApp: MicroApp?
    @State private var streamedModelText = ""
    @StateObject private var bindingStore = FlashBindingStore()

    @Environment(\.colorScheme) private var colorScheme

    private let suggestions = [
        "Rooftop party board for 11 friends tonight",
        "Crush text decoder with reply ideas",
        "Disposable camera recap from last night",
        "Weekend Catskills escape board",
        "Sleepover movie bracket and snack poll",
        "Birthday dinner seating chaos manager",
    ]

    var body: some View {
        Group {
            switch phase {
            case .compose:
                composeLayout
            case .generating:
                generatingLayout
            case .preview:
                previewLayout
            }
        }
        .background(FlashPalette.canvasLight)
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        #if os(iOS)
        .toolbarBackground(FlashPalette.canvasLight, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { onDismiss() }
            }
            if phase == .preview, draftApp != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDraft() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var navTitle: String {
        switch phase {
        case .compose:    return "New app"
        case .generating: return "Building"
        case .preview:    return draftApp?.title ?? "Preview"
        }
    }

    // MARK: Compose (prompt on bottom)

    private var composeLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("What's your idea?")
                            .font(.title2.weight(.semibold))
                        Text("Describe anything — a trip, a list, or a small tool.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, s in
                            Button(action: { prompt = s; errorMessage = nil }) {
                                Text(s)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                            }
                            if index < suggestions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            composeBottomBar
        }
    }

    private var composeBottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.12)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ContextPillButton(
                        icon: "location.fill",
                        label: locationContext != nil ? "Location on" : "Add location",
                        isActive: locationContext != nil,
                        isLoading: fetchingLocation
                    ) { Task { await toggleLocation() } }

                    ContextPillButton(
                        icon: "calendar",
                        label: calendarContext != nil ? "Calendar on" : "Add calendar",
                        isActive: calendarContext != nil,
                        isLoading: fetchingCalendar
                    ) { Task { await toggleCalendar() } }
                }

                TextField("e.g. surf trip to Malibu with friends", text: $prompt, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.secondaryBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                #if canImport(UIKit)
                PromptPhotoAttachmentStrip(photos: $contextPhotos)
                    .frame(height: contextPhotos.isEmpty ? 60 : nil)
                #endif

                Button(action: startGenerating) {
                    Text("Start")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(canStartBuild
                                    ? Color.primary : Color.secondary.opacity(0.15))
                        .foregroundStyle(canStartBuild
                                         ? Color(UIColor.systemBackground) : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(!canStartBuild)

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("\(coinStore.balance) coins · \(CoinStore.buildCost) per build")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? FlashPalette.surfaceDark : Color(UIColor.systemBackground))
        }
    }

    private var canStartBuild: Bool {
        let hasText = !prompt.trimmingCharacters(in: .whitespaces).isEmpty
        #if canImport(UIKit)
        let hasPhotos = !contextPhotos.isEmpty
        return hasText || hasPhotos
        #else
        return hasText
        #endif
    }

    private var generatingPromptSummary: String {
        #if canImport(UIKit)
        if prompt.isEmpty && !contextPhotos.isEmpty {
            return "(Using photos as context)"
        }
        #endif
        return prompt
    }

    private func startGenerating() {
        guard coinStore.canAffordBuild else {
            errorMessage = "You need at least \(CoinStore.buildCost) coins to build an app. Open the coin wallet in the toolbar to get more."
            return
        }
        errorMessage = nil
        finishedSteps = []
        liveStep = ""
        revealedApp = nil
        phase = .generating
    }

    // MARK: Generating (preview appears above, prompt bar below)

    private var generatingLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    generatingStepsSection

                    ZStack(alignment: .topLeading) {
                        if let app = revealedApp {
                            microAppPreviewCard(for: app)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                    removal: .opacity
                                ))
                        } else {
                            loadingPlaceholderCard
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: revealedApp?.id)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

            generatingBottomBar
        }
        .task(id: phase) {
            guard phase == .generating else { return }
            await runGeneration()
        }
    }

    private var generatingStepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(finishedSteps.enumerated()), id: \.offset) { _, label in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !liveStep.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.85)
                    Text(liveStep)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var loadingPlaceholderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .frame(height: 18)
                .frame(maxWidth: 220)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .frame(height: 14)
                .frame(maxWidth: 160)
            Spacer().frame(height: 8)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .frame(height: 120)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(FlashPalette.microAppCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.06), lineWidth: 1)
        )
    }

    private func microAppPreviewCard(for app: MicroApp) -> some View {
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
        .environment(\.skinPalette, SkinPalette.appDefault(appAccentHex: app.accent))
        .environmentObject(bindingStore)
    }

    private var generatingBottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.12)
            VStack(alignment: .leading, spacing: 8) {
                #if canImport(UIKit)
                if !contextPhotos.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(contextPhotos.count) reference photo(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 3)
                    Text(generatingPromptSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? FlashPalette.surfaceDark : Color(UIColor.systemBackground))
        }
    }

    @MainActor
    private func runGeneration() async {
        finishedSteps = []
        liveStep = "Preparing request…"
        revealedApp = nil
        streamedModelText = ""
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        #if canImport(UIKit)
        let attachments = contextPhotos.map(\.attachment)
        #else
        let attachments: [ImageContextAttachment] = []
        #endif
        do {
            let app = try await generateMicroApp(
                prompt: trimmed,
                imageContext: attachments,
                locationContext: locationContext,
                calendarContext: calendarContext,
                onTextDelta: { delta in
                    await MainActor.run {
                        streamedModelText += delta
                        if liveStep.hasPrefix("Streaming layout") || liveStep.isEmpty {
                            let count = streamedModelText.count
                            liveStep = "Streaming layout… \(count) chars"
                        }
                    }
                }
            ) { msg in
                await MainActor.run {
                    if !liveStep.isEmpty { finishedSteps.append(liveStep) }
                    liveStep = msg
                }
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                revealedApp = app
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard coinStore.spendForBuild() else {
                errorMessage = "Could not update your coin balance. Try again."
                phase = .compose
                return
            }
            draftApp = MicroApp(
                id: app.id,
                title: app.title,
                icon: app.icon,
                accent: app.accent,
                body: app.body,
                prompt: draftPromptFrom(trimmed: trimmed, generated: app)
            )
            draftPrompt = draftApp?.prompt ?? trimmed
            #if canImport(UIKit)
            contextPhotos = []
            #endif
            phase = .preview
        } catch {
            errorMessage = error.localizedDescription
            phase = .compose
        }
    }

    private func draftPromptFrom(trimmed: String, generated: MicroApp) -> String? {
        if let p = generated.prompt, !p.isEmpty { return p }
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: Preview (app above, editable prompt below — Save persists)

    private var previewLayout: some View {
        Group {
            if let app = draftApp {
                VStack(spacing: 0) {
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
                        .padding(.bottom, 8)
                        .environment(\.skinPalette, SkinPalette.appDefault(appAccentHex: app.accent))
                        .environmentObject(bindingStore)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity)

                    previewEditBar
                }
            } else {
                Color.clear.onAppear { phase = .compose }
            }
        }
        .background(FlashPalette.microAppDetailChrome)
    }

    private var previewEditBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.12)
            VStack(alignment: .leading, spacing: 6) {
                Text("Your idea")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Edit description…", text: $draftPrompt, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...8)
                    .padding(12)
                    .background(Color.secondaryBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text("Save adds this app to your library. You can change the text above before saving.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? FlashPalette.surfaceDark : Color(UIColor.systemBackground))
        }
    }

    private func saveDraft() {
        guard let app = draftApp else { return }
        let trimmed = draftPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = MicroApp(
            id: app.id,
            title: app.title,
            icon: app.icon,
            accent: app.accent,
            body: app.body,
            prompt: trimmed.isEmpty ? nil : trimmed
        )
        onSave(saved)
    }

    // MARK: Context toggles

    private func toggleLocation() async {
        if locationContext != nil { locationContext = nil; return }
        fetchingLocation = true
        locationContext = await LocationContext.shared.fetchLocation()
        fetchingLocation = false
    }

    private func toggleCalendar() async {
        if calendarContext != nil { calendarContext = nil; return }
        fetchingCalendar = true
        calendarContext = await CalendarContext.shared.fetchUpcomingEvents()
        fetchingCalendar = false
    }
}

// MARK: - Context pill button

private struct ContextPillButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.caption.weight(.medium))
                }
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? Color.primary : Color.primary.opacity(0.07))
            .foregroundStyle(isActive
                ? Color(UIColor.systemBackground)
                : Color.primary.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#if DEBUG
struct CreateView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateView(onDismiss: {}, onSave: { _ in })
        }
        .environmentObject(CoinStore())
    }
}
#endif
