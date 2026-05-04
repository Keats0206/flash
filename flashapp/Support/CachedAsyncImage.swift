import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - Cache

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 150
        cache.totalCostLimit = 80 * 1024 * 1024 // 80 MB
    }

    subscript(url: URL) -> UIImage? {
        get { cache.object(forKey: url as NSURL) }
        set {
            if let img = newValue {
                cache.setObject(img, forKey: url as NSURL, cost: img.jpegData(compressionQuality: 0.5)?.count ?? 0)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }
}

// MARK: - Phase

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}

// MARK: - View

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (CachedImagePhase) -> Content

    @State private var phase: CachedImagePhase = .empty

    init(url: URL?, @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { phase = .failure(URLError(.badURL)); return }

        if let cached = ImageCache.shared[url] {
            phase = .success(Image(uiImage: cached))
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let ui = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            ImageCache.shared[url] = ui
            phase = .success(Image(uiImage: ui))
        } catch {
            phase = .failure(error)
        }
    }
}
#else
// Non-UIKit fallback — just wraps AsyncImage with matching API
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        AsyncImage(url: url, content: content)
    }
}
#endif
