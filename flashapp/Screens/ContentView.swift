import SwiftUI

private enum HomeDestination: Hashable {
    case microApp(UUID)
    case friends
    case create
    case coins
}

struct ContentView: View {
    @State private var userApps: [MicroApp] = Self.loadUserApps()
    @State private var path = NavigationPath()
    @State private var showSettings = false
    @State private var hasLoadedFromCloud = false

    @EnvironmentObject private var sharedInbox: SharedInboxStore

    private var allAppsInGallery: [MicroApp] {
        DemoCatalog.apps + userApps
    }
 
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(spacing: 0) {
                        ForEach(Array(DemoCatalog.apps.enumerated()), id: \.element.id) { i, app in
                            appLinkRow(app, isDemo: true)
                            if i < DemoCatalog.apps.count - 1 {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if userApps.isEmpty {
                        EmptyStateView { path.append(HomeDestination.create) }
                            .padding(.horizontal, 20)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your apps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 0) {
                                ForEach(Array(userApps.enumerated()), id: \.element.id) { i, app in
                                    appLinkRow(app, isDemo: false)
                                    if i < userApps.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(FlashPalette.canvasLight)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Button(action: { path.append(HomeDestination.create) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                            Text("New app")
                                .font(.body.weight(.semibold))
                        }
                        #if canImport(UIKit)
                        .foregroundStyle(Color(UIColor.systemBackground))
                        #else
                        .foregroundStyle(.white)
                        #endif
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New app")
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(FlashPalette.canvasLight.ignoresSafeArea(edges: .bottom))
            }
            #if os(iOS)
            .navigationTitle("Flash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FlashPalette.canvasLight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: HomeDestination.friends) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.2.fill")
                                .font(.body.weight(.medium))
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                            if sharedInbox.unreadCount > 0 {
                                Text(sharedInbox.unreadCount > 8 ? "9+" : "\(sharedInbox.unreadCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 9, y: -7)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Friends")
                }
    
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.medium))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HomeDestination.coins) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.body.weight(.medium))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Coins and balance")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .friends:
                    FriendsView(onInstallSharedApp: { microApp in
                        userApps.insert(microApp, at: 0)
                    })
                case .create:
                    CreateView(
                        onDismiss: { path.removeLast() },
                        onSave: { newApp in
                            userApps.insert(newApp, at: 0)
                            path.removeLast()
                            path.append(HomeDestination.microApp(newApp.id))
                            Task { try? await SupabaseService.shared.saveApp(newApp) }
                        }
                    )
                case .coins:
                    CoinsView()
                case .microApp(let id):
                    if let app = allAppsInGallery.first(where: { $0.id == id }) {
                        MicroAppView(
                            app: app,
                            showsEditChrome: !DemoCatalog.isDemo(id: app.id)
                        ) { updated in
                            guard !DemoCatalog.isDemo(id: updated.id) else { return }
                            if let idx = userApps.firstIndex(where: { $0.id == updated.id }) {
                                userApps[idx] = updated
                            }
                            Task { try? await SupabaseService.shared.saveApp(updated) }
                        }
                    }
                }
            }
        }
        .background(FlashPalette.canvasLight.ignoresSafeArea())
        .task {
            guard !hasLoadedFromCloud else { return }
            hasLoadedFromCloud = true
            await syncFromCloud()
        }
        .onChange(of: userApps.map(\.id)) { _, _ in saveUserApps() }
        .onOpenURL { url in
            guard let imported = MicroApp.decode(fromFlashURL: url) else { return }
            userApps.insert(imported, at: 0)
            saveUserApps()
            path.append(HomeDestination.microApp(imported.id))
        }
    }

    private func appLinkRow(_ app: MicroApp, isDemo: Bool) -> some View {
        NavigationLink(value: HomeDestination.microApp(app.id)) {
            AppCard(app: app, isDemo: isDemo)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Duplicate", systemImage: "plus.square.on.square") {
                let copy = MicroApp(
                    title: app.title + (isDemo ? " (yours)" : " (copy)"),
                    icon: app.icon,
                    accent: app.accent,
                    body: app.body,
                    prompt: app.prompt
                )
                userApps.insert(copy, at: 0)
            }
            if !isDemo {
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    let id = app.id
                    userApps.removeAll { $0.id == id }
                    Task { try? await SupabaseService.shared.deleteApp(id: id) }
                }
            }
        }
    }

    private static func loadUserApps() -> [MicroApp] {
        if let data = UserDefaults.standard.data(forKey: "savedApps"),
           let decoded = try? JSONDecoder().decode([MicroApp].self, from: data) {
            return decoded
        }
        return []
    }

    private func saveUserApps() {
        if let data = try? JSONEncoder().encode(userApps) {
            UserDefaults.standard.set(data, forKey: "savedApps")
        }
    }

    private func syncFromCloud() async {
        guard SupabaseService.shared.isAuthenticated else { return }
        guard let cloud = try? await SupabaseService.shared.fetchApps() else { return }
        let localIDs = Set(userApps.map(\.id))
        let newFromCloud = cloud.filter { !localIDs.contains($0.id) }
        if !newFromCloud.isEmpty {
            userApps.append(contentsOf: newFromCloud)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let onCreate: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 32)
            Text("No saved apps")
                .font(.title3.weight(.medium))
            Text("Browse demos, duplicate one into your library, or create something new.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Button(action: onCreate) {
                Text("Create")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - App Card
struct AppCard: View {
    let app: MicroApp
    var isDemo: Bool = false
    var accent: Color { Color(hex: app.accent) }

    /// Shown under the title: user prompt when present, else a compact summary of component kinds (demos / legacy).
    var gallerySubtitle: String {
        if let p = app.prompt?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            return Self.truncatePrompt(p)
        }
        return componentKindsPreview
    }

    private static func truncatePrompt(_ s: String, maxLen: Int = 72) -> String {
        guard s.count > maxLen else { return s }
        let end = s.index(s.startIndex, offsetBy: maxLen)
        var t = String(s[..<end]).trimmingCharacters(in: .whitespaces)
        while t.hasSuffix(",") || t.hasSuffix(".") { t.removeLast() }
        return t + "…"
    }

    private var componentKindsPreview: String {
        app.body
            .map(\.type)
            .filter { !["text", "divider", "spacer"].contains($0) }
            .prefix(3)
            .map { t in
                switch t {
                case "hstack", "vstack", "zstack": return "layout"
                case "grid":             return "grid"
                case "hscroll":          return "scroll"
                case "card":             return "card"
                case "swipe":            return "swipe"
                case "pager":            return "pages"
                case "checklist":        return "checklist"
                case "progress":         return "progress"
                case "rating":           return "rating"
                case "meter":            return "meter"
                case "toggle":           return "toggle"
                case "stepper":          return "stepper"
                case "table":            return "table"
                case "tagcloud":         return "tags"
                case "button":           return "button"
                case "image":            return "image"
                case "video":            return "video"
                case "audio":            return "audio"
                case "gallery":          return "gallery"
                case "map":              return "map"
                case "chart":            return "chart"
                case "calendar":         return "cal"
                case "section":          return "section"
                case "list":             return "list"
                case "tabs":             return "tabs"
                case "accordion":        return "accordion"
                case "sheet":            return "sheet"
                case "modal":            return "modal"
                case "nav":              return "nav"
                case "comment":          return "comment"
                case "thread":           return "thread"
                case "reaction":         return "react"
                case "share":            return "share"
                case "vote":             return "vote"
                case "poll":             return "poll"
                case "profile":          return "profile"
                case "presence":         return "presence"
                case "cta":              return "cta"
                case "fab":              return "fab"
                case "timer":            return "timer"
                case "counter":          return "counter"
                case "progress_ring":    return "ring"
                case "form":             return "form"
                case "select":           return "select"
                case "date":             return "date"
                case "upload":           return "upload"
                case "confetti":         return "fx"
                case "tooltip":          return "tip"
                case "badge_stack":      return "badges"
                case "story":            return "story"
                case "icon":             return "icon"
                case "badge":            return "badge"
                case "input":            return "input"
                case "aiquery":          return "ai"
                case "wizard":           return "wizard"
                default:                 return t
                }
            }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: app.icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(accent)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(app.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if isDemo {
                        Text("Demo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                if !gallerySubtitle.isEmpty {
                    Text(gallerySubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CoinStore())
            .environmentObject(SharedInboxStore())
            .environmentObject(SessionStore())
    }
}
#endif
