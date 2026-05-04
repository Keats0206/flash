import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private struct FriendInvite: Identifiable {
    let id = UUID()
    let displayName: String
    let subtitle: String
    let accentHex: String
}

private struct SuggestedPerson: Identifiable {
    let id = UUID()
    let displayName: String
    let reason: String
    let accentHex: String
}

// MARK: - Friends hub (prototype)

struct FriendsView: View {
    enum Segment: String, CaseIterable {
        case inbox = "Inbox"
        case friends = "Friends"
        case invites = "Invites"
        case discover = "Discover"
    }

    @EnvironmentObject private var sharedInbox: SharedInboxStore
    @EnvironmentObject private var session: SessionStore

    /// Adds an accepted share into the gallery (`userApps`).
    var onInstallSharedApp: (MicroApp) -> Void

    @State private var segment: Segment = .inbox
    @State private var query = ""

    private let mockFriends = DemoFriends.all

    private let mockInvites: [FriendInvite] = [
        FriendInvite(displayName: "Riley Chen", subtitle: "1 mutual friend", accentHex: "#F4B95E"),
        FriendInvite(displayName: "Taylor Brooks", subtitle: "From your contacts", accentHex: "#B6DE6F"),
        FriendInvite(displayName: "Jamie Nguyen", subtitle: "2 mutual friends", accentHex: "#5AC8FA"),
        FriendInvite(displayName: "Quinn Foster", subtitle: "From your contacts", accentHex: "#FF2D55"),
    ]

    private let mockSuggested: [SuggestedPerson] = [
        SuggestedPerson(displayName: "Morgan Patel", reason: "Followed by Alex Morgan", accentHex: "#4A8EDB"),
        SuggestedPerson(displayName: "Casey Rivera", reason: "Same city", accentHex: "#FF3B30"),
        SuggestedPerson(displayName: "Avery Kim", reason: "In your contacts", accentHex: "#64D2FF"),
        SuggestedPerson(displayName: "Blake Martinez", reason: "Sam Okonkwo follows", accentHex: "#E56A9A"),
    ]

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredFriends: [FriendProfile] {
        guard !trimmedQuery.isEmpty else { return mockFriends }
        let q = trimmedQuery.lowercased()
        return mockFriends.filter {
            $0.displayName.lowercased().contains(q)
                || $0.handle.lowercased().contains(q)
                || $0.status.lowercased().contains(q)
        }
    }

    private var filteredInvites: [FriendInvite] {
        guard !trimmedQuery.isEmpty else { return mockInvites }
        let q = trimmedQuery.lowercased()
        return mockInvites.filter {
            $0.displayName.lowercased().contains(q)
                || $0.subtitle.lowercased().contains(q)
        }
    }

    private var filteredSuggested: [SuggestedPerson] {
        guard !trimmedQuery.isEmpty else { return mockSuggested }
        let q = trimmedQuery.lowercased()
        return mockSuggested.filter {
            $0.displayName.lowercased().contains(q)
                || $0.reason.lowercased().contains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if session.hasCompletedOnboarding {
                    (Text("Signed in as ") + Text(session.displayName).fontWeight(.semibold))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    switch segment {
                    case .inbox:
                        inboxSection
                    case .friends:
                        friendsSection
                    case .invites:
                        invitesSection
                    case .discover:
                        discoverSection
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FlashPalette.canvasLight)
        .navigationTitle("Friends")
        .searchable(text: $query, prompt: "Find people by name or @handle")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlashPalette.canvasLight, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your friends")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if filteredFriends.isEmpty {
                searchEmptyCard("No friends match “\(trimmedQuery)”.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredFriends.enumerated()), id: \.element.id) { i, f in
                        friendRow(f)
                        if i < filteredFriends.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color.systemBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }

            Text("Tip: From any micro-app, use Share › Send to friend… — deliveries land here so you can Add to your apps.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending apps")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Prototype inbox: sending to someone queues an incoming share on this device so you can try Accept.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            if sharedInbox.pending.isEmpty {
                Text(trimmedQuery.isEmpty ? "Nothing pending — open a micro-app, tap Share, then Send to friend." : "No inbox items match “\(trimmedQuery)”.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                let filtered = filteredPending
                if filtered.isEmpty {
                    searchEmptyCard("No inbox items match “\(trimmedQuery)”.")
                } else {
                    VStack(spacing: 12) {
                        ForEach(filtered) { item in
                            pendingShareCard(item)
                        }
                    }
                }
            }
        }
    }

    private var filteredPending: [PendingSharedApp] {
        guard !trimmedQuery.isEmpty else { return sharedInbox.pending }
        let q = trimmedQuery.lowercased()
        return sharedInbox.pending.filter {
            $0.app.title.lowercased().contains(q)
                || $0.senderDisplayName.lowercased().contains(q)
                || $0.senderHandle.lowercased().contains(q)
        }
    }

    private func pendingShareCard(_ item: PendingSharedApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#4A8EDB"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.app.title)
                        .font(.body.weight(.semibold))
                    Text("From \(item.senderDisplayName) · \(item.senderHandle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button(action: { sharedInbox.dismiss(id: item.id) }) {
                    Text("Dismiss")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondaryBg)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                Button(action: {
                    if let installed = sharedInbox.acceptAndRemove(id: item.id) {
                        onInstallSharedApp(installed)
                    }
                }) {
                    Text("Add to my apps")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primary)
                        .foregroundStyle(primaryButtonLabel)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.systemBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func friendRow(_ f: FriendProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: f.accentHex))
            VStack(alignment: .leading, spacing: 2) {
                Text(f.displayName)
                    .font(.body.weight(.medium))
                Text("\(f.handle) · \(f.status)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
                .font(.body.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requests")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if filteredInvites.isEmpty {
                Text(trimmedQuery.isEmpty ? "No pending invites" : "No invites match “\(trimmedQuery)”.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredInvites) { inv in
                        inviteCard(inv)
                    }
                }
            }
        }
    }

    private func inviteCard(_ inv: FriendInvite) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: inv.accentHex))
                VStack(alignment: .leading, spacing: 2) {
                    Text(inv.displayName)
                        .font(.body.weight(.semibold))
                    Text(inv.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button(action: {}) {
                    Text("Ignore")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondaryBg)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                Button(action: {}) {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primary)
                        .foregroundStyle(primaryButtonLabel)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.systemBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People you may know")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if filteredSuggested.isEmpty {
                searchEmptyCard("No suggestions match “\(trimmedQuery)”.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredSuggested.enumerated()), id: \.element.id) { i, p in
                        suggestedRow(p)
                        if i < filteredSuggested.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color.systemBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }

            Button(action: {}) {
                Label("Invite from Contacts", systemImage: "person.crop.circle.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.secondaryBg)
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func suggestedRow(_ p: SuggestedPerson) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: p.accentHex))
            VStack(alignment: .leading, spacing: 2) {
                Text(p.displayName)
                    .font(.body.weight(.medium))
                Text(p.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: {}) {
                Text("Add")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func searchEmptyCard(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(Color.systemBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .accessibilityLabel(message)
    }

    private var primaryButtonLabel: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #else
        Color.white
        #endif
    }
}

#if DEBUG
struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FriendsView(onInstallSharedApp: { _ in })
        }
        .environmentObject(SharedInboxStore())
        .environmentObject(SessionStore())
    }
}
#endif
