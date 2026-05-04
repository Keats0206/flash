import Foundation
import SwiftUI

/// One pending micro-app “delivery” in the prototype Friends inbox.
struct PendingSharedApp: Identifiable, Codable {
    let id: UUID
    /// Shown as sender — in this prototype we simulate the chosen friend as sender so you can test Accept on one device.
    let senderDisplayName: String
    let senderHandle: String
    let createdAt: Date
    let app: MicroApp
}

final class SharedInboxStore: ObservableObject {
    @Published private(set) var pending: [PendingSharedApp] = []

    private let defaults = UserDefaults.standard
    private static let key = "flash.sharedInbox.pending"

    init() {
        load()
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([PendingSharedApp].self, from: data) else {
            pending = []
            return
        }
        pending = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(pending) {
            defaults.set(data, forKey: Self.key)
        }
    }

    /// Queues an incoming row as if `friend` shared `app` with you (single-device demo).
    func addSimulatedDelivery(from friend: FriendProfile, app: MicroApp) {
        let row = PendingSharedApp(
            id: UUID(),
            senderDisplayName: friend.displayName,
            senderHandle: friend.handle,
            createdAt: Date(),
            app: app
        )
        pending.insert(row, at: 0)
        save()
    }

    func dismiss(id: UUID) {
        pending.removeAll { $0.id == id }
        save()
    }

    /// Removes from inbox and returns a fresh `MicroApp` id suitable for `userApps`.
    func acceptAndRemove(id: UUID) -> MicroApp? {
        guard let idx = pending.firstIndex(where: { $0.id == id }) else { return nil }
        let row = pending.remove(at: idx)
        save()
        return MicroApp(
            id: UUID(),
            title: row.app.title,
            icon: row.app.icon,
            accent: row.app.accent,
            body: row.app.body,
            prompt: row.app.prompt
        )
    }

    var unreadCount: Int { pending.count }
}
