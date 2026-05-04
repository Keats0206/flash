import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum FlashActionKind: Equatable {
    case openURL(URL)
    case copyText(String)
    case shareText(String)
    case shareURL(URL)
}

enum FlashActionParser {
    static func parse(_ raw: String?) -> FlashActionKind? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if let payload = payload(for: "url:", in: trimmed) ?? payload(for: "open:", in: trimmed),
           let url = normalizedURL(from: payload) {
            return .openURL(url)
        }
        if let payload = payload(for: "copy:", in: trimmed) {
            return .copyText(payload)
        }
        if let payload = payload(for: "share_text:", in: trimmed) {
            return .shareText(payload)
        }
        if let payload = payload(for: "share_url:", in: trimmed),
           let url = normalizedURL(from: payload) {
            return .shareURL(url)
        }
        return nil
    }

    private static func payload(for prefix: String, in value: String) -> String? {
        guard value.lowercased().hasPrefix(prefix) else { return nil }
        return String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedURL(from value: String) -> URL? {
        var text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.contains("://") {
            text = "https://" + text
        }
        return URL(string: text)
    }
}

@MainActor
enum FlashActionRuntime {
    static func perform(_ action: FlashActionKind) {
        switch action {
        case .openURL(let url):
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        case .copyText(let text):
            #if canImport(UIKit)
            UIPasteboard.general.string = text
            #endif
        case .shareText(let text):
            presentShareSheet(items: [text])
        case .shareURL(let url):
            presentShareSheet(items: [url])
        }
    }

    static func perform(from component: Component, fallbackText: String? = nil) {
        if let action = FlashActionParser.parse(component.action) {
            perform(action)
            return
        }
        if let text = fallbackText, let action = FlashActionParser.parse("copy:\(text)") {
            perform(action)
        }
    }

    private static func presentShareSheet(items: [Any]) {
        #if os(iOS)
        guard !items.isEmpty else { return }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            av.popoverPresentationController?.sourceView = window
            window.rootViewController?.present(av, animated: true)
        }
        #endif
    }
}
