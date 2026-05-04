import Foundation

/// Loads extra demo apps from `SampleApps.json` in the app bundle.
/// Edit that JSON to add or tweak samples without touching Swift.
enum SampleApps {
    static func loadBundled() -> [MicroApp] {
        guard let url = Bundle.main.url(forResource: "SampleApps", withExtension: "json") else {
            #if DEBUG
            print("SampleApps: missing bundled SampleApps.json")
            #endif
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([MicroApp].self, from: data)
        } catch {
            #if DEBUG
            print("SampleApps: failed to load \(url.lastPathComponent): \(error)")
            #endif
            return []
        }
    }
}
