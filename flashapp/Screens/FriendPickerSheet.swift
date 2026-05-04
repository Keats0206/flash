import SwiftUI

/// Pick a mock friend; queues a simulated incoming share in `SharedInboxStore`.
struct FriendPickerSheet: View {
    let app: MicroApp
    @Binding var isPresented: Bool
    var onQueued: () -> Void = {}

    @EnvironmentObject private var inbox: SharedInboxStore

    var body: some View {
        NavigationStack {
            List(DemoFriends.all) { friend in
                Button {
                    let payload = MicroApp(
                        id: UUID(),
                        title: app.title,
                        icon: app.icon,
                        accent: app.accent,
                        body: app.body,
                        prompt: app.prompt
                    )
                    inbox.addSimulatedDelivery(from: friend, app: payload)
                    onQueued()
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: friend.accentHex))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(friend.handle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Send to friend")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

#if DEBUG
struct FriendPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        FriendPickerSheet(
            app: DemoCatalog.apps[0],
            isPresented: .constant(true)
        )
        .environmentObject(SharedInboxStore())
    }
}
#endif
