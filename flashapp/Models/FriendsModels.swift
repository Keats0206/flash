import Foundation

// MARK: - Mock friend (prototype social graph)

struct FriendProfile: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let handle: String
    let status: String
    let accentHex: String
}

enum DemoFriends {
    static let all: [FriendProfile] = [
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111101")!, displayName: "Alex Morgan", handle: "@alex", status: "Active now", accentHex: "#4A8EDB"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111102")!, displayName: "Sam Okonkwo", handle: "@sam_o", status: "Building in Flash", accentHex: "#E56A9A"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111103")!, displayName: "Jordan Lee", handle: "@jordee", status: "Last active 2h ago", accentHex: "#8FAFBE"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111104")!, displayName: "Priya Desai", handle: "@priya", status: "In a micro-app", accentHex: "#7B68EE"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111105")!, displayName: "Chris Park", handle: "@cpark", status: "Active now", accentHex: "#34C759"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111106")!, displayName: "Emma Wilson", handle: "@emma_w", status: "Last active yesterday", accentHex: "#FF9500"),
        FriendProfile(id: UUID(uuidString: "A1111111-1111-1111-1111-111111111107")!, displayName: "Diego Flores", handle: "@dflores", status: "Building in Flash", accentHex: "#AF52DE"),
    ]
}
