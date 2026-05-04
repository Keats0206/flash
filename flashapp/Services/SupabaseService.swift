import Foundation

// MARK: - Public API

struct SupabaseService {
    static let shared = SupabaseService()

    private var projectURL: String { Config.supabaseURL }
    private var anonKey: String { Config.supabaseAnonKey }
    private var accessToken: String? { Keychain.read(key: "supabase.accessToken") }

    var isAuthenticated: Bool {
        guard let t = accessToken else { return false }
        return !t.isEmpty
    }

    private var authHeaders: [String: String] {
        [
            "apikey": anonKey,
            "Authorization": "Bearer \(accessToken ?? anonKey)",
            "Content-Type": "application/json"
        ]
    }

    var isConfigured: Bool { !projectURL.isEmpty && !anonKey.isEmpty }

    // MARK: Auth

    func sendOTP(email: String) async throws {
        let url = URL(string: "\(projectURL)/auth/v1/otp")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "create_user": true])
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode(SupabaseAuthError.self, from: data))?.msg
                ?? "Error sending code (\(http.statusCode))"
            throw SupabaseError.authError(msg)
        }
    }

    func verifyOTP(email: String, token: String) async throws {
        let url = URL(string: "\(projectURL)/auth/v1/verify")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email, "token": token, "type": "email"
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode(SupabaseAuthError.self, from: data))?.error_description
                ?? "Invalid code"
            throw SupabaseError.authError(msg)
        }
        let session = try JSONDecoder().decode(SupabaseAuthSession.self, from: data)
        Keychain.write(key: "supabase.accessToken", value: session.access_token)
        Keychain.write(key: "supabase.userId", value: session.user.id)
    }

    func upsertProfile(firstName: String, lastName: String) async throws {
        guard let uid = Keychain.read(key: "supabase.userId"), isConfigured else { return }
        let url = URL(string: "\(projectURL)/rest/v1/profiles")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        var h = authHeaders
        h["Prefer"] = "resolution=merge-duplicates,return=minimal"
        h.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "id": uid, "first_name": firstName, "last_name": lastName
        ])
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode)
        }
    }

    // MARK: Apps

    func saveApp(_ app: MicroApp) async throws {
        guard isConfigured else { return }
        let url = URL(string: "\(projectURL)/rest/v1/apps")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        var h = authHeaders
        h["Prefer"] = "resolution=merge-duplicates,return=minimal"
        h.forEach { req.setValue($1, forHTTPHeaderField: $0) }

        let bodyData = try JSONEncoder().encode(app.body)
        let bodyJSON = try JSONSerialization.jsonObject(with: bodyData)
        var payload: [String: Any] = [
            "id": app.id.uuidString.lowercased(),
            "title": app.title,
            "icon": app.icon,
            "accent": app.accent,
            "body": bodyJSON
        ]
        if let p = app.prompt { payload["prompt"] = p }
        if let uid = Keychain.read(key: "supabase.userId") { payload["created_by"] = uid }

        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode)
        }
    }

    func fetchApps() async throws -> [MicroApp] {
        guard isConfigured else { return [] }
        var urlStr = "\(projectURL)/rest/v1/apps?order=created_at.desc&limit=100"
        if let uid = Keychain.read(key: "supabase.userId") {
            urlStr += "&created_by=eq.\(uid)"
        }
        let url = URL(string: urlStr)!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode([AppRow].self, from: data).compactMap { $0.toMicroApp() }
    }

    func deleteApp(id: UUID) async throws {
        guard isConfigured else { return }
        let url = URL(string: "\(projectURL)/rest/v1/apps?id=eq.\(id.uuidString.lowercased())")!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        authHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        _ = try? await URLSession.shared.data(for: req)
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case httpError(Int)
    case authError(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Server error (\(code))"
        case .authError(let msg):  return msg
        }
    }
}

// MARK: - Private decodables

private struct SupabaseAuthSession: Decodable {
    let access_token: String
    let user: SupabaseUser
}

private struct SupabaseUser: Decodable { let id: String }

private struct SupabaseAuthError: Decodable {
    let msg: String?
    let error_description: String?
}

private struct AppRow: Decodable {
    let id: String
    let title: String
    let icon: String
    let accent: String
    let body: [Component]
    let prompt: String?

    func toMicroApp() -> MicroApp? {
        MicroApp(
            id: UUID(uuidString: id) ?? UUID(),
            title: title, icon: icon, accent: accent,
            body: body, prompt: prompt
        )
    }
}
