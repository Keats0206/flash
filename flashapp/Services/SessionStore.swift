import Foundation
import SwiftUI

final class SessionStore: ObservableObject {
    @Published private(set) var firstName: String = ""
    @Published private(set) var lastName: String = ""
    @Published private(set) var email: String = ""

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let firstName = "flash.session.firstName"
        static let lastName  = "flash.session.lastName"
        static let email     = "flash.session.email"
    }

    init() {
        firstName = defaults.string(forKey: Keys.firstName) ?? ""
        lastName  = defaults.string(forKey: Keys.lastName)  ?? ""
        email     = defaults.string(forKey: Keys.email)     ?? ""
    }

    var hasCompletedOnboarding: Bool { !firstName.isEmpty }

    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "You" : full
    }

    func completeOnboarding(firstName: String, lastName: String, email: String) {
        let fn = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fn.isEmpty else { return }
        self.firstName = fn
        self.lastName  = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email     = email
        defaults.set(self.firstName, forKey: Keys.firstName)
        defaults.set(self.lastName,  forKey: Keys.lastName)
        defaults.set(self.email,     forKey: Keys.email)
    }
}
