import EventKit
import Foundation

final class CalendarContext {
    static let shared = CalendarContext()
    private let store = EKEventStore()

    func fetchUpcomingEvents() async -> String? {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { ok, _ in cont.resume(returning: ok) }
            }
        }
        guard granted else { return nil }

        let now = Date()
        guard let twoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: now) else { return nil }
        let pred = store.predicateForEvents(withStart: now, end: twoWeeks, calendars: nil)
        let events = store.events(matching: pred)
            .filter { !($0.title?.isEmpty ?? true) }
            .prefix(15)

        guard !events.isEmpty else { return nil }

        let df = DateFormatter()
        df.dateFormat = "EEE MMM d"
        let lines = events.map { "\(df.string(from: $0.startDate)): \($0.title ?? "Event")" }
        return "Upcoming calendar events:\n" + lines.joined(separator: "\n")
    }
}
