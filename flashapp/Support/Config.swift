import Foundation

enum Config {
// MARK: Supabase

    static let supabaseURL = "https://ykvbisbiuaxosjdfyrzx.supabase.co"
    static let supabaseAnonKey = "sb_publishable_sD9L09F8sS4TXGz5ZMaPaQ_MuupApOu"

    private static let anthropicModelKey = "anthropicModelId"
    static let defaultAnthropicModel = "claude-haiku-4-5"
    static let promptRefinementModel = "claude-haiku-4-5"
    static let allowedAccentHexes = [
        "#4A8EDB", "#FF3B30", "#F4B95E", "#E56A9A",
        "#8FAFBE", "#B6DE6F", "#EFC1C9", "#F5E51B",
    ]

    static var anthropicModel: String {
        let saved = UserDefaults.standard.string(forKey: anthropicModelKey)
        let trimmed = saved?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let t = trimmed, !t.isEmpty { return t }
        return defaultAnthropicModel
    }

    static func setAnthropicModel(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: anthropicModelKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: anthropicModelKey)
        }
    }
}
